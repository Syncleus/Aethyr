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

# ----------------------------
#  HELPER METHODS (private)
# ----------------------------
module IntegrationHelpers
  DEFAULT_BOOT_TIMEOUT = 15 # seconds – allow ample startup time

  # Waits until the TCP port is accepting connections or times out.
  # Rather than relying on log output, we probe the port directly which is a
  # more robust indicator of readiness.
  #
  # @param port [Integer] Port number to probe
  # @param timeout [Integer] seconds before giving up
  # @return [void]
  def wait_for_port(port, timeout: DEFAULT_BOOT_TIMEOUT)
    deadline = Time.now + timeout
    until Time.now > deadline
      begin
        socket = TCPSocket.new('127.0.0.1', port)
        socket.close
        return # success
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
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

  # Start the server via the repository script directly to avoid PATH issues.
  @server_process = run_command('bin/aethyr')

  wait_for_port(port)
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
  # Ensure the server process is terminated even if the scenario fails.
  stop_all_commands
end 