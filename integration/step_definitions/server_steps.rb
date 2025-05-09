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
  port = ServerConfig.port

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