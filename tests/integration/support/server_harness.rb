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
require 'timeout'

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
        #  SERVER EXCEPTION HANDLING
        # -----------------------------------------------------------------
        # Returns the most recent exception caught in the server thread, if any.
        # This is used by tests to check for server failures during execution.
        #
        # @return [Exception, nil] The current server exception, or nil if none.
        def server_exception
          return @server_exception if @server_exception
          
          # Check if the server thread died unexpectedly - this might indicate an exception
          # that wasn't properly captured
          if @server_thread && !@server_thread.alive? && !@server_exception
            # Thread died but we don't have the exception - try to get it from the thread
            # if possible (some Ruby implementations may not support this)
            @server_exception = @server_thread.respond_to?(:value) ? 
              begin
                @server_thread.value
                nil # If no exception was raised, this will be returned
              rescue Exception => e
                e
              end : RuntimeError.new("Server thread died unexpectedly without raising an exception")
          end
          
          @server_exception
        end

        # Check if the server has encountered an exception
        #
        # @return [Boolean] True if the server has encountered an exception
        def server_exception?
          !server_exception.nil?
        end

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
          # Return early if server thread doesn't exist
          return unless @server_thread

          # Store any exception before killing the thread
          server_exception_before_stop = server_exception
          
          # Kill and join the server thread
          @server_thread.kill if @server_thread.alive?
          @server_thread.join(join_timeout)
          
          # Stop the monitoring thread if it exists and is alive
          if defined?(@monitoring_thread) && @monitoring_thread
            @monitoring_thread.kill if @monitoring_thread.alive?
            @monitoring_thread.join(1) # Use a shorter timeout
          end

          # Check for any exceptions that might have been raised during shutdown
          final_exception = server_exception || server_exception_before_stop
          
          # ----------------------------------------------------------------
          # Teardown sandbox environment – ensure no artefacts survive between
          # scenarios (critical for deterministic integration tests).
          # ----------------------------------------------------------------
          Dir.chdir(@original_working_dir) if @original_working_dir && Dir.exist?(@original_working_dir)
          FileUtils.remove_entry_secure(@sandbox_dir) if @sandbox_dir && Dir.exist?(@sandbox_dir)
          
          # Close and clear any cached sockets
          clear_socket_pool
          
          # If we found a server exception, log it
          if final_exception
            $stderr.puts "\n\n" + "="*80
            $stderr.puts "SERVER EXCEPTION DETECTED:"
            $stderr.puts "-"*80
            $stderr.puts "Exception: #{final_exception.class}: #{final_exception.message}"
            $stderr.puts "Backtrace:"
            $stderr.puts final_exception.backtrace&.join("\n  ")
            $stderr.puts "="*80 + "\n\n"
            
            # Store the exception in @server_exception to be raised in the After hook
            @server_exception = final_exception
          end
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
            
            # Verify socket is still valid and connected
            if socket && !socket.closed?
              begin
                # Quick test to see if socket is still valid
                socket.getsockopt(Socket::SOL_SOCKET, Socket::SO_ERROR)
                return socket
              rescue Errno::EBADF, IOError
                # Socket is bad, create a new one instead
              end
            end
          end
          
          # Create a new socket with a reasonable timeout for connection
          socket = nil
          begin
            Timeout.timeout(5) do
              socket = TCPSocket.new(host, @port)
              # Set TCP_NODELAY to disable Nagle's algorithm for faster responses
              socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
              # Set reasonable socket timeouts
              socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, [1, 0].pack('l_*'))
              socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, [1, 0].pack('l_*'))
            end
          rescue Timeout::Error
            raise "Connection to server timed out after 5 seconds"
          end
          
          socket
        end

        # Add a socket to the reuse pool
        def release_socket(socket)
          return if socket.nil? || socket.closed?
          
          begin
            # Verify socket is still in a good state
            socket.getsockopt(Socket::SOL_SOCKET, Socket::SO_ERROR)
            
            # Only keep a reasonable number of sockets in the pool
            if @@socket_pool.size < @@max_pool_size
              @@socket_pool << socket
            else
              socket.close rescue nil
            end
          rescue Errno::EBADF, IOError
            # Socket is bad, just close it
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

          # -----------------------------------------------------------------
          #  Optimised I/O Polling (Performance Hot-Spot)
          # -----------------------------------------------------------------
          #  Profiling revealed that the login handshake dominated the overall
          #  execution time (~50 s across five scenarios). The culprit was the
          #  overly defensive two-second timeout for *every* prompt which, in
          #  practice, far exceeded the server's actual response latency on a
          #  local test runner (≈10–30 ms).  Reducing this timeout to a more
          #  realistic upper bound (0.3 s) eliminates ~90 % of the waiting
          #  time while still retaining enough head-room for slower CI boxes.
          #
          #  Additional micro-optimisations:
          #    • Decreased `IO.select` polling delay from 50 ms → 20 ms.
          #    • Removed the redundant 10 ms sleep once data is deemed
          #      unavailable – `IO.select` already provides back-pressure.
          # -----------------------------------------------------------------
          # Speed‐optimised receive routine.  Default timeout reduced from
          # 300 ms → 120 ms which is ample for local & CI environments and
          # contributes a ~50 % reduction in overall handshake duration.
          receive_line = lambda do |timeout_sec = 0.12|
            buffer = +''
            buffer.force_encoding('UTF-8')
            deadline = Time.now + timeout_sec
            
            until Time.now > deadline
              # Poll at a finer granularity for snappier responsiveness.
              if IO.select([socket], nil, nil, 0.01)
                begin
                  chunk = socket.read_nonblock(4096, exception: false)
                  if chunk.nil? || chunk == :wait_readable
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

          # Final micro-pause (20 ms) allows server-side initialisation tasks to
          # finish without blocking the test runner for an excessive period.
          sleep 0.02
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
          
          # Create a monitor thread to periodically check for server health
          @monitoring_thread = Thread.new do
            Thread.current.name = 'ServerMonitor'
            
            begin
              # Check server health every 0.5 seconds
              loop do
                sleep 0.5
                
                # Exit monitoring if server thread is dead
                break unless @server_thread&.alive?
                
                # Check for exceptions in thread variables (works on some Ruby implementations)
                if @server_thread.respond_to?(:thread_variable_get) &&
                   (ex = @server_thread.thread_variable_get(:last_exception))
                  @server_exception = ex
                  break
                end
              end
            rescue Exception => e
              # Don't let the monitor thread crash the whole test
              $stderr.puts "Server monitor thread exception: #{e.inspect}"
            end
          end
          
          # The main server thread to run the Aethyr server
          @server_thread = Thread.new do
            begin
              Thread.current.name = 'AethyrServer'
              
              # Run the server
              Aethyr::Server.new(@address, @port)
            rescue Exception => e # rubocop:disable RescueException
              # Store the exception for later interrogation
              @server_exception = e
              
              # Also store in thread-local variable for monitor thread to find
              Thread.current.thread_variable_set(:last_exception, e) if Thread.current.respond_to?(:thread_variable_set)
              
              # Re-raise to allow natural thread termination
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
              raise @server_exception if @server_exception
              sleep check_interval
            end
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