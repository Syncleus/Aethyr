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
  # Class-level socket buffer cache for better performance
  @socket_buffers = {}
  @socket_buffer_max_size = 50
  @client_socket_cache = {}
  @character_login_cache = {}
  @layout_cache = {}
  @command_response_cache = {}

  # Method to access module instance variables
  def self.socket_buffers
    @socket_buffers
  end

  def self.socket_buffer_max_size
    @socket_buffer_max_size
  end

  def self.client_socket_cache
    @client_socket_cache
  end

  def self.character_login_cache
    @character_login_cache
  end

  def self.layout_cache
    @layout_cache
  end

  def self.command_response_cache
    @command_response_cache
  end

  # Reads all currently available data from a socket within a timeout window.
  # This drains the receive buffer without blocking the test execution.
  # Optimized with buffers cache and improved read logic for better performance.
  #
  # @param socket [TCPSocket] The active client connection socket
  # @param timeout_seconds [Numeric] Maximum time to wait for data
  # @return [String] The received data as a string
  def drain_socket(socket, timeout_seconds = 0.5)
    return '' if socket.nil? || socket.closed?
    
    socket_id = socket.object_id
    
    # Initialize buffer for this socket if not exists
    MultipleClientsHelpers.socket_buffers[socket_id] ||= +''
    buffer = MultipleClientsHelpers.socket_buffers[socket_id]
    
    # Clear the buffer before reading
    buffer.clear
    
    deadline = Time.now + timeout_seconds
    chunk_size = 8192  # Larger chunk size for more efficient reads
    
    loop do
      remaining = deadline - Time.now
      break if remaining <= 0

      # Wait for socket to be ready with shorter timeout
      ready = IO.select([socket], nil, nil, [remaining, 0.05].min)
      break unless ready
      
      begin
        # Use read_nonblock for better performance
        chunk = socket.read_nonblock(chunk_size, exception: false)
        
        # Break if no more data or connection closed
        break if chunk.nil? || chunk == :wait_readable
        
        # Append chunk to buffer
        buffer << chunk
      rescue EOFError, IOError
        # Connection closed or errored
        break
      end
    end
    
    # Clean up buffer cache if it grows too large
    if MultipleClientsHelpers.socket_buffers.size > MultipleClientsHelpers.socket_buffer_max_size
      MultipleClientsHelpers.socket_buffers.clear
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
  
  # Cache the reference for faster access
  MultipleClientsHelpers.client_socket_cache[client_name] = @client_sockets[client_name]
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

  # Check if this character has already been created and cached
  cache_key = "#{client_name}:#{character_name}"
  if MultipleClientsHelpers.character_login_cache[cache_key]
    # Just drain the buffer if it's a cached character
    drain_socket(socket)
    return
  end

  # A deterministic yet trivial password that fulfils the server's validation criteria
  password = 'pass123'

  # The full sign-up flow condensed into a sequence
  # Send all commands with minimal delay
  [
    'n',               # Disable colour support
    '2',               # Create new character
    character_name,    # Character name
    'M',               # Sex selection
    password,          # Password
    'n'                # Disable colour post-creation
  ].each do |input|
    socket.write("#{input}\n")
    # Use shorter sleep time for better performance
    sleep 0.05
  end

  # Give the server time to finalize player creation (reduced time)
  sleep 0.5

  # Drain bootstrap text
  drain_socket(socket)
  
  # Cache this character login
  MultipleClientsHelpers.character_login_cache[cache_key] = true
end

# -----------------------------------------------------------------------------
#  Command Execution
# -----------------------------------------------------------------------------

# Change layout for a specific client
When('I switch layout to {string} for {string}') do |layout, client_name|
  socket = @client_sockets[client_name]
  assert_not_nil(socket, "Client socket for '#{client_name}' not found")
  
  # Check if this layout has already been set for this client
  cache_key = "#{client_name}:layout:#{layout}"
  unless MultipleClientsHelpers.layout_cache[cache_key]
    command = "SET LAYOUT #{layout}\n"
    socket.write(command)
    # Shorter sleep time
    sleep 0.1
    
    # Cache this layout setting
    MultipleClientsHelpers.layout_cache[cache_key] = true
  end
  
  # Store the response for potential later assertion
  @last_responses ||= {}
  @last_responses[client_name] = drain_socket(socket)
end

# Send a command on a specific connection
When('I type {string} on connection {string}') do |command, client_name|
  socket = @client_sockets[client_name]
  assert_not_nil(socket, "Client socket for '#{client_name}' not found")
  
  # Send the command to the server
  socket.write("#{command}\n")
  
  # Use a shorter, consistent wait time for better performance
  sleep 0.1
  
  # Store the response for later assertion
  @last_responses ||= {}
  @last_responses[client_name] = drain_socket(socket)
  
  # Cache the response for potential reuse
  cache_key = "#{client_name}:command:#{command}"
  MultipleClientsHelpers.command_response_cache[cache_key] = @last_responses[client_name]
  
  # Clean up cache if it gets too large
  if MultipleClientsHelpers.command_response_cache.size > 100
    MultipleClientsHelpers.command_response_cache.clear
  end
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
    # Release the socket back to the pool instead of closing
    server_harness.release_socket(socket) 
    @client_sockets.delete(client_name)
  end
end 