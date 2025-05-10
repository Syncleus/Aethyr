# frozen_string_literal: true

################################################################################
#  Multiple Clients Integration Test Step Definitions
# -----------------------------------------------------------------------------
#  These steps implement the ability to manage multiple simultaneous client
#  connections to the Aethyr server. They allow tests to connect as multiple
#  distinct characters and issue commands on each connection independently.
#
#  @author Jeffrey Phillips Freeman
################################################################################

require 'test/unit/assertions'
require 'securerandom'
require 'timeout'

World(Test::Unit::Assertions)

# -----------------------------------------------------------------------------
#  H E L P E R S
# -----------------------------------------------------------------------------
module MultipleClientsHelpers
  # Reads all currently available data from a socket within a timeout window.
  # This drains the receive buffer without blocking the test execution.
  #
  # @param socket [TCPSocket] The active client connection socket
  # @param timeout_seconds [Numeric] Maximum time to wait for data
  # @return [String] The received data as a string
  def drain_socket(socket, timeout_seconds = 1.0)
    buffer = +''
    deadline = Time.now + timeout_seconds

    loop do
      remaining = deadline - Time.now
      break if remaining <= 0

      ready = IO.select([socket], nil, nil, remaining)
      break unless ready

      begin
        chunk = socket.read_nonblock(4096, exception: false)
        break unless chunk
        buffer << chunk
      rescue IO::WaitReadable
        # Nothing to read right now, try again later
        sleep 0.1
      rescue EOFError, IOError
        # Connection closed or errored
        break
      end
    end

    buffer
  end
end

World(MultipleClientsHelpers)

# -----------------------------------------------------------------------------
#  Connection Management
# -----------------------------------------------------------------------------

# Opens a named client connection for tracking multiple simultaneous connections
When('I connect as client {string}') do |client_name|
  # Initialize the client sockets hash if it doesn't exist
  @client_sockets ||= {}
  
  # Create a new socket for this named client
  @client_sockets[client_name] = server_harness.open_client_socket
end

# Verify a specific client connection succeeded
Then('the connection for {string} should succeed') do |client_name|
  socket = @client_sockets[client_name]
  assert_not_nil(socket, "Socket for client '#{client_name}' was not found")
  assert(socket.is_a?(TCPSocket), "Connection for '#{client_name}' did not return a TCPSocket")
  assert(!socket.closed?, "Socket for '#{client_name}' unexpectedly closed immediately after connection")
end

# Create and log in as a named character on a specific connection
And('I have created and logged in as a new character named {string} on connection {string}') do |character_name, client_name|
  socket = @client_sockets[client_name]
  assert_not_nil(socket, "Client socket for '#{client_name}' not initialized")

  # A deterministic yet trivial password that fulfils the server's validation
  # criteria (6-20 word characters).
  password = 'pass123'

  # The full sign-up flow condensed into a sequence
  login_sequence = [
    'n',               # Disable colour support
    '2',               # Create new character
    character_name,    # Character name
    'M',               # Sex selection
    password,          # Password
    'n'                # Disable colour post-creation
  ]

  login_sequence.each do |input|
    socket.write("#{input}\n")
    sleep 0.15
  end

  # Give the server time to finalize player creation
  sleep 1.0

  # Drain bootstrap text
  drain_socket(socket)
end

# -----------------------------------------------------------------------------
#  Command Execution
# -----------------------------------------------------------------------------

# Change layout for a specific client
When('I switch layout to {string} for {string}') do |layout, client_name|
  socket = @client_sockets[client_name]
  assert_not_nil(socket, "Client socket for '#{client_name}' not found")
  
  command = "SET LAYOUT #{layout}\n"
  socket.write(command)
  # Allow time for the server to process the command
  sleep 0.25
  
  # Store the response for potential later assertion
  @last_responses ||= {}
  @last_responses[client_name] = drain_socket(socket)
end

# Send a command on a specific connection
When('I type {string} on connection {string}') do |command, client_name|
  socket = @client_sockets[client_name]
  assert_not_nil(socket, "Client socket for '#{client_name}' not found")
  
  socket.write("#{command}\n")
  # Allow time for the server to process the command
  sleep 0.25
  
  # Store the response for later assertion
  @last_responses ||= {}
  @last_responses[client_name] = drain_socket(socket)
end

# -----------------------------------------------------------------------------
#  Assertions
# -----------------------------------------------------------------------------

# Check that text was received on a specific connection
Then('I should see text in {string}') do |client_name|
  @last_responses ||= {}
  response = @last_responses[client_name]
  
  assert_not_nil(response, "No response captured for client '#{client_name}'")
  assert(response.strip.length > 0, "Expected non-empty response for client '#{client_name}', but got nothing")
end

# -----------------------------------------------------------------------------
#  Cleanup
# -----------------------------------------------------------------------------

# Disconnect a specific client
And('I disconnect client {string}') do |client_name|
  socket = @client_sockets[client_name]
  if socket && !socket.closed?
    socket.close
  end
end 