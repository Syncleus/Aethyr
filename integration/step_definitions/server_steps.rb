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
  DEFAULT_BOOT_TIMEOUT = 5 # seconds – adequate for local CI

  # Block until the server process signals readiness or timeout is reached.
  # Uses a very simple heuristic – the magic string printed by the bootstrap
  # code when the listener has been bound.  This remains implementation detail
  # hidden behind a tiny façade which can be adapted if Aethyr changes.
  #
  # @param server_process [Aruba::Processes::Process] handle returned by Aruba
  # @param timeout        [Integer] seconds before we abort
  # @return [void]
  def wait_for_server_start(server_process, timeout: DEFAULT_BOOT_TIMEOUT)
    deadline = Time.now + timeout
    loop do
      raise 'Server did not start within expected time' if Time.now > deadline

      out = server_process.stdout + server_process.stderr
      break if out.include?('Server up and running') # magic string from server.rb

      sleep 0.1
    end
  end
end
World(IntegrationHelpers)

# -----------------------------------------------------------------------------
#  Step: Given the server is running
# -----------------------------------------------------------------------------
Given('the Aethyr server is running') do
  # Launch the server via the published executable to stay as close to the user
  # journey as possible – this maximises confidence that the packaging works.
  @server_process = run_command('aethyr')

  wait_for_server_start(@server_process)
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
  # Ensure the server is terminated even if the scenario fails.
  if defined?(@server_process) && @server_process&.alive?
    stop_processes!
  end
end 