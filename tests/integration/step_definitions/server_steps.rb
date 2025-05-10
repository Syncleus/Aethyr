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

# Load reusable server harness (auto-loaded by Cucumber as well, but requiring
# explicitly here clarifies the dependency graph and aids static analysis).
require_relative '../support/server_harness'

# ---------------------------------------------------------------------------
#  Helper Accessors
# ---------------------------------------------------------------------------
# Inject a convenience accessor into the Cucumber World so that *any* step
# definition can reference the current harness (should a scenario comprise
# multiple files).  The instance variable lives inside the World object which
# survives for the duration of the scenario, thereby providing natural scoping
# semantics.
#
# NOTE: We deliberately avoid the Singleton pattern for the harness itself to
# ensure isolation between scenarios – each maintains its own dedicated server
# instance which eliminates cross-test interference.
module HarnessAccessor
  def server_harness
    @server_harness
  end

  def server_harness=(harness)
    @server_harness = harness
  end
end
World(HarnessAccessor)

# -----------------------------------------------------------------------------
#  Step: Given the server is running
# -----------------------------------------------------------------------------
Given('the Aethyr server is running') do
  # Leverage the reusable harness which automatically selects a free port and
  # blocks until the server becomes reachable.
  self.server_harness = Aethyr::Test::Integration::ServerHarness.build.start!
end

# -----------------------------------------------------------------------------
#  Step: When I connect as a client
# -----------------------------------------------------------------------------
When('I connect as a client') do
  @client_socket = server_harness.open_client_socket
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
  @client_sockets = Array.new(count) { server_harness.open_client_socket }
end

Then('all clients should remain connected') do
  assert_not_nil(@client_sockets, 'Client socket collection was not initialised')
  assert(@client_sockets.all? { |s| !s.closed? }, 'One or more client sockets closed unexpectedly')
end

And('I disconnect all clients') do
  @client_sockets&.each(&:close)
end

# -----------------------------------------------------------------------------
#  Step: Given/When I log in as the default test user
# -----------------------------------------------------------------------------
Given('I log in as the default test user') do
  # Ensure any previous socket is closed to avoid descriptor leaks when this
  # step is used after an explicit connection in the same scenario.
  @client_socket&.close if defined?(@client_socket) && @client_socket

  # Delegate the heavy lifting to the new helper exposed by ServerHarness.
  @client_socket = server_harness.open_authenticated_socket

  # Drain the welcome banner so subsequent assertions operate on the command
  # under test rather than login noise.
  if respond_to?(:drain_socket)
    drain_socket(@client_socket)
  end
end

# -----------------------------------------------------------------------------
#  T E A R D O W N
# -----------------------------------------------------------------------------
After do
  # Ensure the harness (if one was created) is properly shut down to avoid
  # leaking background threads between scenarios.
  server_harness&.stop!
end 