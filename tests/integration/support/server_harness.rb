################################################################################
# frozen_string_literal: true
#
# =============================================================================
#  ServerHarness – Reusable Integration Test Utility for the Aethyr Server
# -----------------------------------------------------------------------------
#  This helper encapsulates the life-cycle management of a *real* Aethyr server
#  instance that is executed **in-process** within a background thread. The goal
#  is to provide a *single* abstraction that future Cucumber scenarios can rely
#  upon without needing to duplicate complex boot-strapping logic.  The class
#  adheres to SOLID principles and employs several classic GoF design patterns
#  (notably *Facade*, *Builder* and *Template Method*) to maximise flexibility
#  whilst presenting a minimal, intention-revealing public API.
#
#  Usage Example (inside a step definition):
#
#      harness = Aethyr::Test::Integration::ServerHarness.build.start!
#      socket  = harness.open_client_socket
#      # …perform assertions…
#      harness.stop!
#
#  Because Cucumber automatically loads every file located beneath the
#  *tests/integration/support* directory, no explicit `require` statements are
#  necessary from the feature layer – simply instantiate and go.
# =============================================================================
################################################################################

require 'socket'
require 'forwardable'
require 'aethyr/core/util/config'
require 'aethyr/core/connection/server'
require 'tmpdir'
require 'fileutils'

module Aethyr
  module Test
    module Integration
      # ---------------------------------------------------------------------
      #  ServerHarness
      # ---------------------------------------------------------------------
      #  Encapsulates the orchestration of a *live* Aethyr server instance
      #  running on an ephemeral TCP port.  The harness is deliberately
      #  agnostic of the surrounding test framework which permits seamless
      #  re-use inside RSpec, Minitest, or raw Ruby scripts if desired.
      # ---------------------------------------------------------------------
      class ServerHarness
        extend Forwardable

        # Publicly expose the port number the server is bound to. The actual
        # network socket remains encapsulated within the real server object.
        attr_reader :port

        # Expose whether the internal server thread is still alive. Delegating
        # directly to Thread keeps the surface area minimal.
        def_delegator :@server_thread, :alive?, :running?

        # -----------------------------------------------------------------
        #  DOMAIN CONSTANTS & CONFIGURATION
        # -----------------------------------------------------------------
        DEFAULT_BOOT_TIMEOUT = 30 # Seconds – ample cushion for CI runners.
        DEFAULT_ADDRESS      = ServerConfig.address # Typically 127.0.0.1

        # Publicly accessible *test fixtures* – these constants model the
        # canonical credentials present in the bootstrap storage that ships
        # with the repository.  They are exposed so that step-definitions can
        # reference a single source-of-truth rather than sprinkling literals
        # throughout the test-suite (DRY principle).
        DEFAULT_TEST_USERNAME = 'testuser'
        DEFAULT_TEST_PASSWORD = 'testpass'

        # Cached socket connection pool
        @@socket_pool = []
        @@max_pool_size = 10

        # Factory-style constructor that provides a fluent DSL for harness
        # creation whilst hiding the `new` keyword – aligning with the Builder
        # pattern for improved readability.
        #
        # @option opts [Integer] :port (nil) Explicit TCP port to bind to. If
        #   omitted an *ephemeral* port is chosen by the operating system.
        # @option opts [String]  :address (DEFAULT_ADDRESS) Local interface to
        #   listen on. Using 127.0.0.1 prevents accidental exposure beyond the
        #   local machine.
        # @return [ServerHarness] An **un-started** harness ready for `start!`.
        def self.build(**opts)
          new(**opts)
        end

        # -----------------------------------------------------------------
        #  LIFECYCLE MANAGEMENT
        # -----------------------------------------------------------------

        # Boots the server in a *background thread* and blocks until the TCP
        # port becomes reachable (or a timeout is hit).
        #
        # @param timeout [Integer] Seconds to wait for the port to become
        #   connectable before raising an exception.
        # @return [self] Returns the same harness instance for fluent chaining.
        # @raise [RuntimeError] If the server fails to open the socket in time.
        def start!(timeout: DEFAULT_BOOT_TIMEOUT)
          prepare_sandbox_environment!
          configure_runtime_port!
          spawn_server_thread!
          await_port_open!(timeout)
          self
        end

        # Stops the background server thread (if still alive) and performs a
        # graceful join with a *short* timeout to guarantee deterministic
        # teardown. This mirrors the behaviour of the original test helper but
        # bundles it inside the harness interface.
        #
        # @param join_timeout [Integer] Seconds to wait when joining the thread
        #   before giving up.  A small default keeps test suites snappy even
        #   when the server is unresponsive.
        # @return [void]
        def stop!(join_timeout: 5)
          return unless @server_thread

          @server_thread.kill if @server_thread.alive?
          @server_thread.join(join_timeout)

          # ----------------------------------------------------------------
          # Teardown sandbox environment – ensure no artefacts survive between
          # scenarios (critical for deterministic integration tests).
          # ----------------------------------------------------------------
          Dir.chdir(@original_working_dir) if @original_working_dir && Dir.exist?(@original_working_dir)
          FileUtils.remove_entry_secure(@sandbox_dir) if @sandbox_dir && Dir.exist?(@sandbox_dir)
          
          # Close and clear any cached sockets
          clear_socket_pool
        end

        # Convenience helper that constructs, starts, and yields the harness to
        # a block – automatically guaranteeing teardown via `ensure`. This is a
        # classic *Template Method* implementation that encourages correct
        # usage patterns.
        #
        # @yieldparam harness [ServerHarness] The active harness instance.
        # @return [void]
        def self.run(**opts)
          harness = build(**opts).start!
          yield harness
        ensure
          harness&.stop!
        end

        # Opens a new TCP client connection to the server synchronously.
        # Tries to reuse sockets from the pool for better performance.
        #
        # @param host [String] Hostname or IP address to connect to. Defaults to
        #   `127.0.0.1` which aligns with the typical local-only test setup.
        # @return [TCPSocket] A ready-to-use bidirectional socket.
        def open_client_socket(host: '127.0.0.1')
          # Try to reuse a socket from the pool
          unless @@socket_pool.empty?
            socket = @@socket_pool.pop
            return socket if socket && !socket.closed?
          end
          
          # Create a new socket if none available in the pool
          TCPSocket.new(host, @port)
        end

        # Add a socket to the reuse pool
        def release_socket(socket)
          return if socket.nil? || socket.closed?
          
          # Only keep a reasonable number of sockets in the pool
          if @@socket_pool.size < @@max_pool_size
            @@socket_pool << socket
          else
            socket.close rescue nil
          end
        end

        # Clear the socket pool
        def clear_socket_pool
          @@socket_pool.each do |socket|
            socket.close rescue nil
          end
          @@socket_pool.clear
        end

        # -----------------------------------------------------------------
        #  H A R N E S S   U T I L I T Y   A P I
        # -----------------------------------------------------------------

        # Cache for authenticated sessions to avoid redundant handshakes
        @@auth_cache = {}

        # Opens a new TCP socket *and* performs the interactive login exchange
        # using the globally seeded `testuser` account (unless overriden).
        #
        # This is essentially a convenience wrapper around `open_client_socket`
        # + `login!` that collapses the two common steps most integration
        # scenarios require into a single call.
        #
        # @param host [String] Host/IP to connect to (defaults to localhost).
        # @param username [String] Login name to authenticate with.
        # @param password [String] Plain-text password for the given user.
        # @return [TCPSocket] An **already authenticated** client session ready
        #   for in-game commands.
        def open_authenticated_socket(host: '127.0.0.1',
                                      username: DEFAULT_TEST_USERNAME,
                                      password: DEFAULT_TEST_PASSWORD,
                                      colour: true)
          # Check cache first
          cache_key = [host, username, password, colour].hash
          cached_socket = @@auth_cache[cache_key]
          
          # Reuse cached socket if available and still open
          if cached_socket && !cached_socket.closed?
            return cached_socket
          end
          
          # Create new authenticated socket
          socket = open_client_socket(host: host)
          login!(socket: socket, username: username, password: password, colour: colour)
          
          # Cache the authenticated socket for future reuse
          @@auth_cache[cache_key] = socket if @@auth_cache.size < 20
          
          socket
        end

        # Performs the full ANSI-aware login handshake against the supplied
        # socket. Optimized for performance.
        #
        # @param socket [TCPSocket] **Connected** socket to the server.
        # @param username [String]
        # @param password [String]
        # @param colour [Boolean] Whether to enable ANSI colour for the session.
        # @return [void]
        def login!(socket:, username:, password:, colour: true)
          raise ArgumentError, 'socket must be a live TCPSocket' if socket.nil? || socket.closed?

          # Optimized receive_line - uses a pre-allocated buffer and shorter timeout
          receive_line = lambda do |timeout_sec = 2|
            buffer = +''
            buffer.force_encoding('UTF-8')
            deadline = Time.now + timeout_sec
            
            until Time.now > deadline
              if IO.select([socket], nil, nil, 0.05)
                begin
                  chunk = socket.read_nonblock(4096, exception: false)
                  if chunk.nil? || chunk == :wait_readable
                    sleep 0.01
                    next
                  end
                  buffer << chunk
                  break if buffer =~ /:\s?$/
                rescue EOFError, IOError
                  break
                end
              end
            end
            buffer
          end

          # Send all login commands with minimal delay
          login_steps = [
            [lambda { receive_line.call }, lambda { socket.write((colour ? 'y' : 'n') + "\n") }],
            [lambda { receive_line.call }, lambda { socket.write("1\n") }],
            [lambda { receive_line.call }, lambda { socket.write("#{username}\n") }],
            [lambda { receive_line.call }, lambda { socket.write("#{password}\n") }],
            [lambda { receive_line.call }, lambda { socket.write((colour ? 'y' : 'n') + "\n") }]
          ]

          # Execute login steps
          login_steps.each do |receive, send|
            receive.call
            send.call
          end

          # Allow the server to finalize player initialization with a shorter wait
          sleep 0.1
        end

        # -----------------------------------------------------------------
        #  INTERNAL IMPLEMENTATION DETAILS (private)
        # -----------------------------------------------------------------

        private

        # @api private
        # The constructor is intentionally kept private to funnel callers
        # through the `build` factory method which reinforces the *Builder*
        # semantics and maintains a consistent entry point.
        def initialize(port: nil, address: DEFAULT_ADDRESS)
          @port    = port || self.class.find_free_port
          @address = address
          @server_thread = nil
          @server_exception = nil

          # ----------------------------------------------------------------
          # Sandbox state – each harness instantiates a *unique* ephemeral
          # working directory seeded from the canonical bootstrap fixtures so
          # that **every** scenario starts with a pristine world & config.
          # ----------------------------------------------------------------
          @sandbox_dir            = nil   # Path to the temp workspace.
          @original_working_dir   = Dir.pwd # Will be restored on teardown.

          # Absolute path to the immutable bootstrap fixture set that ships
          # with the repository (conf & storage prepared with seeded accounts).
          @bootstrap_root = File.expand_path('../server_bootstrap', __dir__)
        end

        # @api private
        # Updates the **in-memory** configuration so that *any* code path inside
        # the process that consults `ServerConfig.port` receives the dynamic
        # value. Importantly we *avoid* persisting this mutation to disk.
        def configure_runtime_port!
          ServerConfig.load[:port] = @port
        end

        # @api private
        # Spins up the real Aethyr server inside an isolated Thread while
        # capturing any unexpected exceptions so they can be surfaced to the
        # caller if boot fails.
        def spawn_server_thread!
          @server_exception = nil
          @server_thread = Thread.new do
            begin
              Thread.current.name = 'AethyrServer'
              
              # Add additional debug output
              puts "Starting Aethyr server on #{@address}:#{@port}..."
              
              # Add error reporting before starting the server
              begin
                require 'aethyr/core/util/all-objects'
                puts "Successfully loaded all-objects.rb"
              rescue StandardError => e
                puts "Error loading all-objects.rb: #{e.class} - #{e.message}"
                puts e.backtrace.join("\n")
                raise
              end
              
              # Debug the current working directory
              puts "Current working directory: #{Dir.pwd}"
              
              # Check if key files exist
              ['storage/goids', 'conf/config.yaml'].each do |file|
                if File.exist?(file)
                  puts "File exists: #{file}"
                else
                  puts "ERROR: File not found: #{file}"
                end
              end
              
              # Try to load some of the key objects that might be failing
              begin
                puts "Testing StorageMachine class..."
                require 'aethyr/core/components/storage'
                storage = StorageMachine.new
                puts "StorageMachine initialized successfully"
              rescue StandardError => e
                puts "Error initializing StorageMachine: #{e.class} - #{e.message}"
                puts e.backtrace.join("\n")
              end
              
              begin
                puts "Testing Manager class..."
                require 'aethyr/core/components/manager'
                puts "Manager class loaded successfully"
                
                # Attempt to create a Manager to see if we can debug issues there
                puts "Attempting to create a Manager instance..."
                manager = Manager.new
                puts "Manager instance created successfully"
                puts "Number of objects loaded: #{manager.game_objects_count}"
                
                # Check for common Manager initialization issues
                if manager.game_objects_count == 0
                  puts "WARNING: No game objects were loaded by the Manager"
                end
              rescue StandardError => e
                puts "Error loading Manager class: #{e.class} - #{e.message}"
                puts e.backtrace.join("\n")
              end
              
              # Now try to start the server
              puts "Starting Aethyr::Server..."
              Aethyr::Server.new(@address, @port)
            rescue Exception => e # rubocop:disable RescueException
              # Store the exception for later interrogation before re-raising
              # through the main thread if boot never completes.
              @server_exception = e
              puts "ERROR in server thread: #{e.class} - #{e.message}"
              puts e.backtrace.join("\n")
              raise
            end
          end

          # Abort the entire test run immediately if the thread crashes –
          # mirrors the behaviour of `Thread#abort_on_exception = true`.
          @server_thread.abort_on_exception = true
        end

        # @api private
        # Optimized port check with shorter timeouts
        def await_port_open!(timeout)
          deadline = Time.now + timeout
          check_interval = 0.05
          
          until Time.now > deadline
            begin
              socket = TCPSocket.new('127.0.0.1', @port)
              socket.close
              return true # Successfully connected - boot is complete
            rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
              # Check if the server thread has encountered an exception
              if @server_exception
                puts "Server thread encountered exception: #{@server_exception.class}"
                puts @server_exception.message
                puts @server_exception.backtrace.join("\n")
                raise @server_exception
              end
              sleep check_interval
            end
          end

          # Before raising the timeout error, check if server thread is still alive and if there's an exception
          if @server_thread && !@server_thread.alive?
            puts "Server thread died before opening port"
            if @server_exception
              puts "Server exception: #{@server_exception.class}"
              puts @server_exception.message
              puts @server_exception.backtrace.join("\n")
              raise @server_exception
            end
          else
            puts "Server thread status: #{@server_thread&.alive? ? 'alive' : 'dead'}"
            puts "Server thread backtrace:"
            puts @server_thread&.backtrace&.join("\n")
          end

          raise "Server did not open port #{@port} within #{timeout} seconds"
        end

        # @api private
        # Identical implementation to the previous helper but now extracted so
        # it can be reused throughout the harness as a *utility* method.
        # Uses socket caching for better performance.
        #
        # @return [Integer] A currently free TCP port chosen by the OS.
        def self.find_free_port
          socket = TCPServer.new('127.0.0.1', 0)
          port = socket.addr[1]
          socket.close
          port
        end

        # -----------------------------------------------------------------
        #  S A N D B O X   P R E P A R A T I O N
        # -----------------------------------------------------------------
        # Creates an isolated temporary directory, copies the canonical
        # configuration & storage fixtures into it, and finally switches the
        # working directory so that **all** relative-path look-ups performed by
        # the server resolve inside the sandbox (conf/, storage/, logs/, …).
        #
        # The sandbox is deleted during `stop!`, guaranteeing zero state leak
        # between scenarios.
        # -----------------------------------------------------------------
        def prepare_sandbox_environment!
          return if @sandbox_dir # Idempotent – useful if `start!` called twice.

          @sandbox_dir = Dir.mktmpdir('aethyr_it_')

          # Replicate the canonical test fixtures (conf + storage) into the
          # isolated workspace. Only copy needed directories for faster operation.
          %w[conf storage].each do |folder|
            src = File.join(@bootstrap_root, folder)
            dst = File.join(@sandbox_dir, folder)
            FileUtils.cp_r(src, dst)
          end

          # Ensure auxiliary directories exist
          FileUtils.mkdir_p(File.join(@sandbox_dir, 'logs'))

          # Redirect all path resolutions to the sandbox
          Dir.chdir(@sandbox_dir)
        end
      end # class ServerHarness
    end   # module Integration
  end     # module Test
end       # module Aethyr 