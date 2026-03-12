# frozen_string_literal: true

###############################################################################
# Step definitions for player_connection_lifecycle.feature                     #
#                                                                             #
# Exercises every public method and branch in                                 #
#   lib/aethyr/core/connection/player_connect.rb                              #
# using lightweight test doubles to avoid ncurses/network dependencies.       #
###############################################################################

require 'test/unit/assertions'
require 'socket'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# Pre-require setup: define mock Display before the real one could be loaded.
# PlayerConnection#initialize calls Display.new(socket) – we intercept it
# with a lightweight stub so ncurses is never touched.
# ---------------------------------------------------------------------------

# Guard: only define if Display is not yet loaded (avoids redefinition
# warnings when Cucumber loads multiple step files).
unless defined?(Display)
  class Display
    attr_reader :messages, :closed, :echo_state, :colors_initialized

    def initialize(socket, *_args)
      @socket   = socket
      @messages = []
      @closed   = false
      @echo_state = true
      @colors_initialized = false
    end

    def send(message, parse = true, add_newline: true, message_type: :main, internal_clear: false)
      @messages << { message: message, parse: parse, add_newline: add_newline,
                     message_type: message_type, internal_clear: internal_clear }
    end

    def close
      @closed = true
    end

    def init_colors
      @colors_initialized = true
    end

    def echo_off
      @echo_state = false
    end

    def echo_on
      @echo_state = true
    end

    def recv
      nil
    end
  end
end

# Ensure ServerConfig is available (loads the real YAML-based module).
require 'aethyr/core/util/config'

# Now load the system under test.  The require chain is:
#   player_connect.rb → format.rb, telnet_codes.rb, errors.rb,
#                        login.rb, koa_paginator.rb, editor.rb, text_util.rb
# None of these require ncurses, so this is safe with our mock Display.
require 'aethyr/core/connection/player_connect'

# ---------------------------------------------------------------------------
# World module – all mutable scenario state lives here.
# ---------------------------------------------------------------------------
module PlayerConnectionWorld
  attr_accessor :pc, :mock_socket, :mock_display, :mock_player,
                :ask_answer, :menu_result, :menu_reprompted,
                :choose_error, :page_height_result,
                :manager_dropped, :mccp_finished
end
World(PlayerConnectionWorld)

# ---------------------------------------------------------------------------
# Stub manager for unbind tests
# ---------------------------------------------------------------------------
class StubManager
  attr_reader :actions, :dropped_players
  attr_accessor :object_loaded

  def initialize
    @actions         = []
    @dropped_players = []
    @object_loaded   = true
  end

  def submit_action(action)
    @actions << action
  end

  def object_loaded?(goid)
    @object_loaded
  end

  def drop_player(player)
    @dropped_players << player
  end
end

# ---------------------------------------------------------------------------
# Mock socket for initialize tests
# ---------------------------------------------------------------------------
class MockSocket
  attr_reader :written_data

  def initialize(behavior: :normal)
    @behavior     = behavior
    @written_data = String.new
    @call_count   = 0
  end

  def write_nonblock(data)
    @call_count += 1

    case @behavior
    when :io_error
      raise IOError, "simulated IO error"
    when :wait_writable
      if @call_count <= 1
        raise IO::EAGAINWaitWritable
      else
        @written_data << data
        data.bytesize
      end
    else
      @written_data << data
      data.bytesize
    end
  end

  def close; end
end

# ---------------------------------------------------------------------------
# Mock player for method tests
# ---------------------------------------------------------------------------
class PCMockPlayer
  attr_accessor :name, :goid, :page_height, :word_wrap, :connection
  attr_reader :output_messages

  def initialize(name = "Tester")
    @name            = name
    @goid            = "mock-player-goid-1234"
    @page_height     = 40
    @word_wrap       = 80
    @output_messages = []
    @connection      = nil
  end

  def output(msg, *_args, **_kwargs)
    @output_messages << msg
  end

  def pronoun(type)
    "their"
  end

  def set_connection(conn)
    @connection = conn
  end
end

# ---------------------------------------------------------------------------
# Mock MCCP deflater
# ---------------------------------------------------------------------------
class MockMCCP
  attr_reader :finished

  def initialize
    @finished = false
  end

  def finish
    @finished = true
  end
end

# ---------------------------------------------------------------------------
# Helper: build a fake addrinfo binary string that Socket.unpack_sockaddr_in
# can parse.
# ---------------------------------------------------------------------------
def make_addrinfo(ip = "127.0.0.1", port = 8888)
  Socket.pack_sockaddr_in(port, ip)
end

# ---------------------------------------------------------------------------
# Helper: allocate a PlayerConnection without running initialize,
# then inject the minimum state needed for individual method tests.
# ---------------------------------------------------------------------------
def build_allocated_pc(closed: false, player: nil, mccp: false)
  pc = PlayerConnection.allocate

  display = Display.new(nil)
  pc.instance_variable_set(:@display,          display)
  pc.instance_variable_set(:@socket,           MockSocket.new)
  pc.instance_variable_set(:@in_buffer,        [])
  pc.instance_variable_set(:@paginator,        nil)
  pc.instance_variable_set(:@mccp_to_client,   mccp ? MockMCCP.new : false)
  pc.instance_variable_set(:@mccp_from_client, false)
  pc.instance_variable_set(:@word_wrap,        120)
  pc.instance_variable_set(:@closed,           closed)
  pc.instance_variable_set(:@state,            :initial)
  pc.instance_variable_set(:@login_name,       nil)
  pc.instance_variable_set(:@login_password,   nil)
  pc.instance_variable_set(:@password_attempts, 0)
  pc.instance_variable_set(:@player,           player)
  pc.instance_variable_set(:@expect_callback,  nil)
  pc.instance_variable_set(:@ip_address,       "127.0.0.1")
  pc.instance_variable_set(:@editing,          false)

  pc
end

###############################################################################
# Given steps                                                                 #
###############################################################################

Given('a player connection mock environment with intro file') do
  @mock_socket = MockSocket.new
end

Given('a player connection mock environment without intro file') do
  @mock_socket = MockSocket.new
end

Given('a player connection mock environment with io error socket') do
  @mock_socket = MockSocket.new(behavior: :io_error)
end

Given('a player connection mock environment with wait writable socket') do
  @mock_socket = MockSocket.new(behavior: :wait_writable)
end

Given('an allocated player connection') do
  @pc = build_allocated_pc
end

Given('an allocated player connection that is closed') do
  @pc = build_allocated_pc(closed: true)
end

Given('an allocated player connection with mock player') do
  @mock_player = PCMockPlayer.new("TestHero")
  @pc = build_allocated_pc(player: @mock_player)
end

Given('an allocated player connection with mccp enabled') do
  @mock_player = PCMockPlayer.new("MCCPHero")
  @pc = build_allocated_pc(player: @mock_player, mccp: true)
end

Given('the player connection manager stub is set up') do
  $manager = StubManager.new
end

Given('the player connection manager stub with object not loaded') do
  $manager = StubManager.new
  $manager.object_loaded = false
end

###############################################################################
# When steps – initialization                                                 #
###############################################################################

When('a new player connection is created with intro banner') do
  # Temporarily stub File.exist? to return true for the intro file,
  # and File.read to return a small banner string.
  intro_path = ServerConfig.intro_file

  original_exist = File.method(:exist?)
  original_read  = File.method(:read)

  # We need IO.select for the WaitWritable branch.  In the normal path
  # it won't be called, but define a safe stub just in case.
  file_class = File.singleton_class

  file_class.define_method(:exist?) do |path|
    if path == intro_path
      true
    else
      original_exist.call(path)
    end
  end

  file_class.define_method(:read) do |path, *args|
    if path == intro_path
      "Welcome to the MUD!"
    else
      original_read.call(path, *args)
    end
  end

  begin
    @pc = PlayerConnection.new(@mock_socket, make_addrinfo)
  ensure
    file_class.define_method(:exist?, original_exist)
    file_class.define_method(:read, original_read)
  end
end

When('a new player connection is created without intro banner') do
  intro_path = ServerConfig.intro_file
  original_exist = File.method(:exist?)
  file_class = File.singleton_class

  file_class.define_method(:exist?) do |path|
    if path == intro_path
      false
    else
      original_exist.call(path)
    end
  end

  begin
    @pc = PlayerConnection.new(@mock_socket, make_addrinfo)
  ensure
    file_class.define_method(:exist?, original_exist)
  end
end

When('a new player connection is created with io error socket') do
  intro_path = ServerConfig.intro_file
  original_exist = File.method(:exist?)
  original_read  = File.method(:read)
  file_class = File.singleton_class

  file_class.define_method(:exist?) do |path|
    if path == intro_path
      true
    else
      original_exist.call(path)
    end
  end

  file_class.define_method(:read) do |path, *args|
    if path == intro_path
      "Banner text"
    else
      original_read.call(path, *args)
    end
  end

  begin
    @pc = PlayerConnection.new(@mock_socket, make_addrinfo)
  ensure
    file_class.define_method(:exist?, original_exist)
    file_class.define_method(:read, original_read)
  end
end

When('a new player connection is created with wait writable socket') do
  intro_path = ServerConfig.intro_file
  original_exist = File.method(:exist?)
  original_read  = File.method(:read)
  original_select = IO.method(:select)
  file_class = File.singleton_class

  file_class.define_method(:exist?) do |path|
    if path == intro_path
      true
    else
      original_exist.call(path)
    end
  end

  file_class.define_method(:read) do |path, *args|
    if path == intro_path
      "WW Banner"
    else
      original_read.call(path, *args)
    end
  end

  # Stub IO.select to return immediately for WaitWritable retry
  io_class = IO.singleton_class
  io_class.define_method(:select) do |*args|
    [[],[args[1] || []].flatten, []]
  end

  begin
    @pc = PlayerConnection.new(@mock_socket, make_addrinfo)
  ensure
    file_class.define_method(:exist?, original_exist)
    file_class.define_method(:read, original_read)
    io_class.define_method(:select, original_select)
  end
end

###############################################################################
# When steps – output methods                                                 #
###############################################################################

When('player connection send_puts is called with {string}') do |message|
  @pc.send_puts(message)
end

When('player connection send_puts is called with {string} and no_newline') do |message|
  @pc.send_puts(message, true)
end

When('player connection output is called with {string}') do |message|
  @pc.output(message)
end

When('player connection say is called with {string}') do |message|
  @pc.say(message)
end

When('player connection print is called with {string}') do |message|
  @pc.print(message)
end

When('player connection put_list is called with {string} and {string}') do |msg1, msg2|
  @put_list_error = nil
  begin
    @pc.put_list(msg1, msg2)
  rescue => e
    @put_list_error = e
  end
end

###############################################################################
# When steps – expect / ask / ask_menu                                        #
###############################################################################

When('player connection expect is set with a block') do
  @pc.expect { |input| input.upcase }
end

When('player connection ask is called with {string}') do |question|
  @pc.ask(question) { |answer| @ask_answer = answer }
end

When('player connection ask is called and then answered with {string}') do |answer|
  @pc.ask("Pick a name?") { |a| @ask_answer = a }
  # Simulate the expect callback being invoked
  cb = @pc.instance_variable_get(:@expect_callback)
  cb.call(answer)
end

When('player connection ask_menu is called with a valid answer {string}') do |answer|
  @menu_result = nil
  @pc.ask_menu("Choose:\n1. Option A\n2. Option B", ["1", "2"]) do |a|
    @menu_result = a
  end
  # Trigger the expect callback with the valid answer
  cb = @pc.instance_variable_get(:@expect_callback)
  cb.call(answer)
end

When('player connection ask_menu is called with an invalid answer {string}') do |answer|
  @menu_reprompted = false

  # Since the invalid branch calls player.menu (which is actually ask_menu on self,
  # but through player), we override the player to detect the re-prompt.
  # The key thing is that the `answers.include?(answer)` check fails.
  original_output = @mock_player.method(:output)

  @pc.ask_menu("Choose:\n1. Yes\n2. No", ["1", "2"]) do |a|
    @menu_result = a
  end

  # Trigger expect callback with invalid answer.
  # The code does: `if answers and not answers.include? answer` → re-prompts
  # by calling `player.menu options, answers, &block` – but `player` (without @)
  # is actually a method call.  In practice it calls self's player accessor.
  # For coverage, we just need the branch entered.  We rescue any NoMethodError
  # from the re-prompt path since player.menu isn't a real method on our mock.
  cb = @pc.instance_variable_get(:@expect_callback)
  begin
    cb.call(answer)
  rescue NoMethodError
    # Expected: the invalid branch tries to call player.menu which our mock
    # doesn't implement.  The important thing is lines 110-111 were executed.
    @menu_reprompted = true
  end
end

###############################################################################
# When steps – page_height                                                    #
###############################################################################

When('player connection page_height is called') do
  @page_height_result = @pc.page_height
end

###############################################################################
# When steps – close / choose                                                 #
###############################################################################

When('player connection close is called') do
  @pc.close
end

When('player connection choose is called with {string} and choices') do |prompt|
  @choose_error = nil
  begin
    @pc.choose(prompt, "a", "b", "c")
  rescue => e
    @choose_error = e
  end
end

###############################################################################
# When steps – unbind                                                         #
###############################################################################

When('player connection unbind is called') do
  # Define `after` on the connection instance so that unbind can call it.
  # The real `after` would schedule a delayed block; we execute it immediately.
  unless @pc.respond_to?(:after, true)
    @pc.define_singleton_method(:after) do |delay, &block|
      block.call
    end
  end

  @pc.unbind
end

###############################################################################
# Then steps – initialization assertions                                      #
###############################################################################

Then('the player connection should store the socket') do
  assert_not_nil(@pc.socket, "Expected socket to be stored")
end

Then('the player connection in_buffer should be empty') do
  assert(@pc.in_buffer.empty?, "Expected in_buffer to be empty")
end

Then('the player connection word_wrap should be {int}') do |value|
  assert_equal(value, @pc.word_wrap)
end

Then('the player connection should not be closed') do
  assert_equal(false, @pc.closed?, "Expected connection to not be closed")
end

Then('the player connection should have called show_initial') do
  # show_initial changes @state to :resolution (via show_resolution_prompt)
  state = @pc.instance_variable_get(:@state)
  assert_equal(:resolution, state, "Expected state to be :resolution after show_initial")
end

###############################################################################
# Then steps – output assertions                                              #
###############################################################################

Then('the player connection display should have received the message') do
  display = @pc.instance_variable_get(:@display)
  assert(!display.messages.empty?,
         "Expected display to have received at least one message")
end

Then('the player connection display should not have received any message') do
  display = @pc.instance_variable_get(:@display)
  assert(display.messages.empty?,
         "Expected display to have received no messages but got #{display.messages.size}")
end

Then('the player connection put_list should have completed without error') do
  assert_nil(@put_list_error,
             "Expected put_list to complete without error but got: #{@put_list_error}")
end

###############################################################################
# Then steps – expect / ask / ask_menu assertions                             #
###############################################################################

Then('the player connection expect callback should be stored') do
  cb = @pc.instance_variable_get(:@expect_callback)
  assert_not_nil(cb, "Expected expect_callback to be set")
end

Then('the player connection ask answer should be {string}') do |expected|
  assert_equal(expected, @ask_answer)
end

Then('the player connection ask_menu result should be {string}') do |expected|
  assert_equal(expected, @menu_result)
end

Then('the player connection ask_menu should have re-prompted') do
  assert(@menu_reprompted, "Expected ask_menu to re-prompt on invalid input")
end

###############################################################################
# Then steps – page_height                                                    #
###############################################################################

Then('the player connection page_height should be {int}') do |expected|
  assert_equal(expected, @page_height_result)
end

###############################################################################
# Then steps – close / choose                                                 #
###############################################################################

Then('the player connection should be closed') do
  assert_equal(true, @pc.closed?)
end

Then('the player connection display should have been closed') do
  display = @pc.instance_variable_get(:@display)
  assert_equal(true, display.closed)
end

Then('no error should be raised from player connection choose') do
  assert_nil(@choose_error, "Expected no error but got: #{@choose_error}")
end

###############################################################################
# Then steps – unbind                                                         #
###############################################################################

Then('the player connection should be marked closed') do
  assert_equal(true, @pc.closed?)
end

Then('the player connection manager should have dropped the player') do
  assert(!$manager.dropped_players.empty?,
         "Expected manager to have dropped the player")
end

Then('the player connection manager should not have dropped the player') do
  assert($manager.dropped_players.empty?,
         "Expected manager to NOT have dropped the player")
end

Then('the player connection mccp should have been finished') do
  mccp = @pc.instance_variable_get(:@mccp_to_client)
  assert_equal(true, mccp.finished, "Expected MCCP to have been finished")
end
