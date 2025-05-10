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
        # Callers are expected to manage the lifecycle of the returned socket.
        #
        # @param host [String] Hostname or IP address to connect to. Defaults to
        #   `127.0.0.1` which aligns with the typical local-only test setup.
        # @return [TCPSocket] A ready-to-use bidirectional socket.
        def open_client_socket(host: '127.0.0.1')
          TCPSocket.new(host, @port)
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
              Aethyr::Server.new(@address, @port)
            rescue Exception => e # rubocop:disable RescueException
              # Store the exception for later interrogation before re-raising
              # through the main thread if boot never completes.
              @server_exception = e
            end
          end

          # Abort the entire test run immediately if the thread crashes –
          # mirrors the behaviour of `Thread#abort_on_exception = true`.
          @server_thread.abort_on_exception = true
        end

        # @api private
        # Blocks until the server thread has opened its TCP listener or a
        # timeout has elapsed.  Should the underlying thread terminate early
        # the *original* exception is re-raised to preserve full backtrace
        # fidelity.
        def await_port_open!(timeout)
          deadline = Time.now + timeout
          until Time.now > deadline
            begin
              TCPSocket.new('127.0.0.1', @port).close
              return true # Successfully connected – boot is complete.
            rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
              raise @server_exception if @server_exception
              sleep 0.1
            end
          end

          raise "Server did not open port #{@port} within #{timeout} seconds"
        end

        # @api private
        # Identical implementation to the previous helper but now extracted so
        # it can be reused throughout the harness as a *utility* method.
        #
        # @return [Integer] A currently free TCP port chosen by the OS.
        def self.find_free_port
          socket = TCPServer.new('127.0.0.1', 0)
          port   = socket.addr[1]
          socket.close
          port
        end
      end # class ServerHarness
    end   # module Integration
  end     # module Test
end       # module Aethyr 