# frozen_string_literal: true

# =============================================================================
#  Server Integration Test Step Definitions
# -----------------------------------------------------------------------------
#  This file models user-visible behaviour of the *running* Aethyr server.  It
#  deliberately treats the server as a black-box, talking to it exclusively via
#  the public TCP interface.  The heavy lifting of process management is
#  delegated to Aruba which embodies the Command design pattern.
# =============================================================================

require 'test/unit/assertions'
require 'socket'
require 'aethyr/core/util/config'

World(Test::Unit::Assertions)

# Resolve project root directory (three levels up from this file)
PROJECT_ROOT = File.expand_path('../../../', __dir__)

# ----------------------------
#  HELPER METHODS (private)
# ----------------------------
module IntegrationHelpers
  DEFAULT_BOOT_TIMEOUT = 30 # seconds – allow ample startup time

  # Dynamically finds an available TCP port on localhost by binding to port 0.
  # The operating system selects an ephemeral port automatically which is then
  # released immediately after discovery.
  #
  # @return [Integer] A currently unused TCP port number guaranteed to be
  #   available at the moment of invocation.
  def find_free_port
    server = TCPServer.new('127.0.0.1', 0)
    port = server.addr[1]
    server.close
    port
  end

  # Waits until the TCP port is accepting connections or times out.
  #
  # @param port [Integer] Port number to probe
  # @param server_thread [Thread] reference to the server background thread
  # @param timeout [Integer] seconds before giving up
  # @return [void]
  def wait_for_port(port, server_thread, timeout: DEFAULT_BOOT_TIMEOUT)
    deadline = Time.now + timeout
    until Time.now > deadline
      begin
        TCPSocket.new('127.0.0.1', port).close
        return # success
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        unless server_thread&.alive?
          raise "Server thread terminated early. Check server logs/output."
        end
        sleep 0.1
      end
    end
    raise "Server did not open port #{port} within #{timeout} seconds"
  end
end
World(IntegrationHelpers)

# -----------------------------------------------------------------------------
#  Step: Given the server is running
# -----------------------------------------------------------------------------
Given('the Aethyr server is running') do
  # Dynamically allocate a free port to avoid clashes with other services or
  # concurrently running test suites.  This eliminates the risk of `EADDRINUSE`
  # errors which would otherwise occur if the default port (usually 8888) is
  # already occupied.
  port = find_free_port

  # Inject the dynamically chosen port into the in-memory configuration so that
  # all subsequent calls to `ServerConfig.port` within this process reflect the
  # new value.  We deliberately avoid `ServerConfig[:port]=` because that method
  # persists the change to disk which is undesirable during transient test
  # execution.
  ServerConfig.load[:port] = port

  # Boot the server in a background Ruby thread rather than spawning a separate
  # process.  This removes shell indirection and surfaces any exceptions
  # immediately in the test output.
  require 'aethyr/core/connection/server'

  @server_exception = nil
  @server_thread = Thread.new do
    begin
      Thread.current.name = 'AethyrServer'
      Aethyr::Server.new(ServerConfig.address, port)
    rescue Exception => e # rubocop:disable RescueException – we want *everything*
      @server_exception = e
      warn "[Integration] Server thread crashed: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
    end
  end

  # Ensure the thread aborts the run if it dies silently.
  @server_thread.abort_on_exception = true

  wait_for_port(port, @server_thread)
end

# -----------------------------------------------------------------------------
#  Step: When I connect as a client
# -----------------------------------------------------------------------------
When('I connect as a client') do
  port = ServerConfig.port
  @client_socket = TCPSocket.new('127.0.0.1', port)
end

Then('the connection should succeed') do
  assert_not_nil(@client_socket, 'Expected a socket instance but got nil')
  assert(@client_socket.is_a?(TCPSocket), 'Connection did not return a TCPSocket')
  assert(!@client_socket.closed?, 'Socket unexpectedly closed immediately after connection')
end

And('I disconnect') do
  @client_socket&.close
end

# -----------------------------------------------------------------------------
#  Multiple-client scenario
# -----------------------------------------------------------------------------
When('I connect {int} clients') do |count|
  port = ServerConfig.port
  @client_sockets = Array.new(count) { TCPSocket.new('127.0.0.1', port) }
end

Then('all clients should remain connected') do
  assert_not_nil(@client_sockets, 'Client socket collection was not initialised')
  assert(@client_sockets.all? { |s| !s.closed? }, 'One or more client sockets closed unexpectedly')
end

And('I disconnect all clients') do
  @client_sockets&.each(&:close)
end

# -----------------------------------------------------------------------------
#  T E A R D O W N
# -----------------------------------------------------------------------------
After do
  # Terminate background server thread if still alive.
  if defined?(@server_thread) && @server_thread&.alive?
    @server_thread.kill
    @server_thread.join(5)
  end
end 