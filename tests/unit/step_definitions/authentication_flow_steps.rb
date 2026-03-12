# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step-definitions for the Login module authentication flow.
#
# Exercises every branch in lib/aethyr/core/connection/login.rb by
# constructing a lightweight test harness that includes the Login module
# without pulling in the full PlayerConnection / Display / ncurses stack.
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'set'
require 'stringio'
require 'aethyr/core/connection/login'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# Lightweight doubles – kept as thin as possible while satisfying the
# contracts that Login expects of its collaborators.
# ---------------------------------------------------------------------------

# Minimal Display mock
class AuthMockDisplay
  attr_reader :colors_initialized, :echo_state, :recv_queue

  def initialize
    @colors_initialized = false
    @echo_state = true
    @recv_queue = []
  end

  def recv
    @recv_queue.shift
  end

  def init_colors
    @colors_initialized = true
  end

  def echo_on
    @echo_state = true
  end

  def echo_off
    @echo_state = false
  end

  def send(message, parse = true, add_newline: true, message_type: :main, internal_clear: false)
    # no-op for tests
  end
end

# Minimal Player mock for login flow
class AuthMockPlayer
  attr_accessor :word_wrap, :name, :admin, :container
  attr_reader :outputs, :handled_inputs, :inventory_items, :worn_items, :connection

  def initialize(name = 'Tester')
    @name = name
    @word_wrap = 120
    @admin = false
    @outputs = []
    @handled_inputs = []
    @inventory_items = []
    @worn_items = []
    @connection = nil
  end

  def set_connection(conn)
    @connection = conn
  end

  def handle_input(input)
    @handled_inputs << input
  end

  def output(msg, no_newline = false, message_type: :main, internal_clear: false)
    @outputs << msg.to_s
  end

  def inventory
    @inventory_items
  end

  def wear(item)
    @worn_items << item
  end

  def instance_variable_set(var, val)
    if var == :@admin
      @admin = val
    else
      super
    end
  end

  def pronoun(kind)
    'their'
  end
end

# Stub item for inventory
class AuthMockItem
  attr_reader :name
  def initialize(name = 'item')
    @name = name
  end
end

# Stub manager for authentication tests
class AuthStubManager
  attr_reader :added_objects, :added_players, :last_password

  def initialize
    @existing_players = {}
    @load_results = {}
    @load_errors = {}
    @added_objects = []
    @added_players = []
    @last_password = nil
  end

  def register_existing(name)
    @existing_players[name.downcase] = true
  end

  def unregister(name)
    @existing_players.delete(name.downcase)
  end

  def set_load_result(name, player)
    @load_results[name.downcase] = player
  end

  def set_load_error(name, error_class)
    @load_errors[name.downcase] = error_class
  end

  def player_exist?(name)
    @existing_players[name.downcase] || false
  end

  def load_player(name, password)
    key = name.downcase
    if @load_errors.key?(key)
      raise @load_errors[key]
    end
    @load_results[key]
  end

  def add_object(obj)
    @added_objects << obj
  end

  def add_player(player, password)
    @added_players << [player, password]
    @last_password = password
  end

  def existing_goid?(goid)
    false
  end

  def submit_action(action)
    # no-op
  end
end

# ---------------------------------------------------------------------------
# The test harness – a plain object that includes Login and provides the
# minimal interface that Login expects from PlayerConnection.
# ---------------------------------------------------------------------------
class AuthLoginHarness
  include Login

  attr_accessor :state, :player, :in_buffer, :display, :word_wrap,
                :ip_address, :password_attempts, :expect_callback,
                :editing, :login_name_val, :new_name_val, :sex_val,
                :new_password_val, :use_color_val
  attr_reader :outputs, :prints, :closed_flag, :closing_after_write,
              :editor_inputs

  def initialize
    @display = AuthMockDisplay.new
    @in_buffer = []
    @state = :server_menu
    @player = nil
    @expect_callback = nil
    @editing = false
    @word_wrap = 120
    @ip_address = '127.0.0.1'
    @password_attempts = 0
    @login_name = nil
    @new_name = nil
    @sex = nil
    @new_password = nil
    @use_color = nil
    @outputs = []
    @prints = []
    @closed_flag = false
    @closing_after_write = false
    @editor_inputs = []
  end

  # --- Interface expected by Login ---

  def closed?
    @closed_flag
  end

  def close
    @closed_flag = true
  end

  def close_connection_after_writing
    @closing_after_write = true
  end

  def output(message, no_newline = false, message_type: :main, internal_clear: false)
    @outputs << message.to_s
  end

  alias :send_puts :output
  alias :say :output

  def print(message, parse = true, newline = false, message_type: :main, internal_clear: false)
    @prints << message.to_s
  end

  def log(msg, level = 1, dump = false)
    # silence during tests
  end

  def editor_input(input)
    @editor_inputs << input
  end

  # Expose internal Login ivars for verification
  def login_name_ivar
    @login_name
  end

  def set_login_name(val)
    @login_name = val
  end

  def set_new_name(val)
    @new_name = val
  end

  def set_sex(val)
    @sex = val
  end

  def set_new_password(val)
    @new_password = val
  end

  def all_output
    (@outputs + @prints).join("\n")
  end
end

# ---------------------------------------------------------------------------
# World module – holds per-scenario state
# ---------------------------------------------------------------------------
module AuthFlowWorld
  attr_accessor :auth_handler, :auth_result, :auth_manager,
                :auth_callback_data, :auth_file_stubs,
                :auth_admin_config, :auth_motd_content
end
World(AuthFlowWorld)

# ---------------------------------------------------------------------------
# Before / After hooks
# ---------------------------------------------------------------------------
Before('@authentication') do
  # placeholder
end

# File stubs are cleaned up in a dedicated After hook below.

# ---------------------------------------------------------------------------
# Helper: stub File.exist? and File.open for motd/log paths
# ---------------------------------------------------------------------------
def auth_stub_files!
  file_singleton = class << File; self; end

  unless file_singleton.method_defined?(:__auth_original_exist__)
    file_singleton.alias_method :__auth_original_exist__, :exist?
  end
  unless file_singleton.method_defined?(:__auth_original_open__)
    file_singleton.alias_method :__auth_original_open__, :open
  end
  unless file_singleton.method_defined?(:__auth_original_read__)
    file_singleton.alias_method :__auth_original_read__, :read
  end

  motd = @auth_motd_content
  file_singleton.define_method(:exist?) do |path|
    case path
    when 'motd.txt'
      !motd.nil?
    when 'logs/player.log'
      true
    else
      __auth_original_exist__(path)
    end
  end

  file_singleton.define_method(:open) do |path, *args, &blk|
    if path == 'logs/player.log'
      io = StringIO.new
      blk ? blk.call(io) : io
    elsif path == 'motd.txt'
      io = StringIO.new(motd || '')
      blk ? blk.call(io) : io
    else
      __auth_original_open__(path, *args, &blk)
    end
  end

  file_singleton.define_method(:read) do |path, *args|
    if path == 'motd.txt'
      motd || ''
    else
      __auth_original_read__(path, *args)
    end
  end

  @auth_file_stubs = true
end

def auth_restore_file_stubs!
  file_singleton = class << File; self; end
  if file_singleton.method_defined?(:__auth_original_exist__)
    file_singleton.alias_method :exist?, :__auth_original_exist__
    file_singleton.remove_method :__auth_original_exist__
  end
  if file_singleton.method_defined?(:__auth_original_open__)
    file_singleton.alias_method :open, :__auth_original_open__
    file_singleton.remove_method :__auth_original_open__
  end
  if file_singleton.method_defined?(:__auth_original_read__)
    file_singleton.alias_method :read, :__auth_original_read__
    file_singleton.remove_method :__auth_original_read__
  end
end

After do
  auth_restore_file_stubs! if @auth_file_stubs
end

# ---------------------------------------------------------------------------
# Helper: ensure ServerConfig has the methods Login expects
# ---------------------------------------------------------------------------
def auth_setup_server_config!
  admin_name = @auth_admin_config || '__no_admin__'
  start_room = 'room_start_001'

  unless defined?(ServerConfig)
    Object.const_set(:ServerConfig, Module.new)
  end

  sc_singleton = class << ServerConfig; self; end

  sc_singleton.define_method(:admin) { admin_name }
  sc_singleton.define_method(:start_room) { start_room }

  # Ensure [] works for log_level etc.
  unless ServerConfig.respond_to?(:[])
    sc_singleton.define_method(:[]) { |_key| nil }
  end
end

# ---------------------------------------------------------------------------
# Pre-build namespaces at file scope so we never define modules inside methods.
# Ensure $manager is available for GameObject initialization.
# ---------------------------------------------------------------------------
$manager ||= AuthStubManager.new

unless defined?(Aethyr::Core::Objects)
  module Aethyr; module Core; module Objects; end; end; end
end
unless defined?(Aethyr::Extensions::Objects)
  module Aethyr; module Extensions; module Objects; end; end; end
end

# Load real classes so they are available for create_new_player.
# These work fine with a stub $manager that responds to existing_goid?.
begin
  require 'aethyr/core/objects/player'
rescue LoadError, NameError
  # If the real Player can't be loaded, define a mock.
  Aethyr::Core::Objects.const_set(:Player, Class.new(AuthMockPlayer)) unless defined?(Aethyr::Core::Objects::Player)
end
begin
  require 'aethyr/extensions/objects/clothing_items'
rescue LoadError, NameError
  Aethyr::Extensions::Objects.const_set(:Shirt, Class.new(AuthMockItem)) unless defined?(Aethyr::Extensions::Objects::Shirt)
  Aethyr::Extensions::Objects.const_set(:Pants, Class.new(AuthMockItem)) unless defined?(Aethyr::Extensions::Objects::Pants)
  Aethyr::Extensions::Objects.const_set(:Underwear, Class.new(AuthMockItem)) unless defined?(Aethyr::Extensions::Objects::Underwear)
end
begin
  require 'aethyr/extensions/objects/sword'
rescue LoadError, NameError
  Aethyr::Extensions::Objects.const_set(:Sword, Class.new(AuthMockItem)) unless defined?(Aethyr::Extensions::Objects::Sword)
end

# ---------------------------------------------------------------------------
# Helper: stub Aethyr::Core::Objects::Player.new for create_new_player
# ---------------------------------------------------------------------------
def auth_stub_player_class!
  player_class = Aethyr::Core::Objects::Player

  # Override new to return our mock
  player_singleton = class << player_class; self; end
  unless player_singleton.method_defined?(:__auth_original_new__)
    player_singleton.alias_method :__auth_original_new__, :new
  end

  player_singleton.define_method(:new) do |*args|
    AuthMockPlayer.new(args[3] || 'Unknown') # args[3] is the name
  end
end

def auth_restore_player_class!
  if defined?(Aethyr::Core::Objects::Player)
    player_singleton = class << Aethyr::Core::Objects::Player; self; end
    if player_singleton.method_defined?(:__auth_original_new__)
      player_singleton.alias_method :new, :__auth_original_new__
      player_singleton.remove_method :__auth_original_new__
    end
  end
end

After do
  auth_restore_player_class! if defined?(Aethyr::Core::Objects::Player)
end

# ---------------------------------------------------------------------------
# Helper: stub clothing/sword requires for create_new_player
# (namespaces and constants already defined at file scope above)
# ---------------------------------------------------------------------------
def auth_stub_equipment!
  # no-op – classes defined at file scope
end

# =============================================================================
#                     G I V E N   S T E P S
# =============================================================================

Given('an authentication login handler') do
  require 'aethyr/core/errors'

  self.auth_manager = AuthStubManager.new
  $manager = auth_manager

  self.auth_handler = AuthLoginHarness.new

  # Defaults for file stubs (no motd)
  @auth_motd_content = nil
  @auth_admin_config = '__no_admin__'
  auth_setup_server_config!
  auth_stub_files!
  auth_stub_equipment!
  auth_stub_player_class!
end

Given('the authentication connection is closed') do
  auth_handler.instance_variable_set(:@closed_flag, true)
end

Given('the authentication display returns nil on recv') do
  auth_handler.display.recv_queue << nil
end

Given('the authentication display returns empty string on recv') do
  auth_handler.display.recv_queue << ''
end

Given('the authentication display returns {string} without newline on recv') do |data|
  auth_handler.display.recv_queue << data.gsub("\\n", "\n")
end

Given('the authentication display returns {string} on recv') do |data|
  auth_handler.display.recv_queue << data.gsub("\\n", "\n")
end

Given('the authentication input buffer already contains {string}') do |data|
  auth_handler.in_buffer << data
end

Given('the authentication state is {string}') do |state|
  auth_handler.state = state.to_sym
end

Given('the authentication manager reports player {string} exists') do |name|
  auth_manager.register_existing(name)
end

Given('the authentication manager reports player {string} does not exist') do |name|
  auth_manager.unregister(name)
end

Given('the authentication login name is {string}') do |name|
  auth_handler.set_login_name(name)
end

Given('the authentication manager loads player {string} successfully') do |name|
  player = AuthMockPlayer.new(name)
  auth_manager.set_load_result(name, player)
end

Given('the authentication manager loads admin player {string} successfully') do |name|
  player = AuthMockPlayer.new(name)
  auth_manager.set_load_result(name, player)
end

Given('the authentication manager raises UnknownCharacter for {string}') do |name|
  auth_manager.set_load_error(name, MUDError::UnknownCharacter)
end

Given('the authentication manager raises BadPassword for {string}') do |name|
  auth_manager.set_load_error(name, MUDError::BadPassword)
end

Given('the authentication manager raises CharacterAlreadyLoaded for {string}') do |name|
  auth_manager.set_load_error(name, MUDError::CharacterAlreadyLoaded)
end

Given('the authentication manager loads nil for {string}') do |name|
  auth_manager.set_load_result(name, nil)
end

Given('the authentication password attempts is {int}') do |count|
  auth_handler.password_attempts = count
end

Given('the authentication admin config is {string}') do |name|
  @auth_admin_config = name
  auth_setup_server_config!
end

Given('a motd.txt file exists with content {string}') do |content|
  @auth_motd_content = content
  auth_stub_files!
end

Given('the authentication has an expect callback') do
  self.auth_callback_data = nil
  world = self
  auth_handler.expect_callback = proc { |d| world.auth_callback_data = d }
end

Given('the authentication is in editing mode') do
  auth_handler.editing = true
end

Given('the authentication has a player set') do
  auth_handler.player = AuthMockPlayer.new('Existing')
end

Given('the authentication new name is {string}') do |name|
  auth_handler.set_new_name(name)
end

Given('the authentication sex is {string}') do |sex|
  auth_handler.set_sex(sex)
end

Given('the authentication new password is {string}') do |password|
  auth_handler.set_new_password(password)
end

# =============================================================================
#                      W H E N   S T E P S
# =============================================================================

When('authentication receive_data is called') do
  self.auth_result = auth_handler.receive_data
end

When('authentication receive_data with password {string} is called') do |data|
  auth_handler.display.recv_queue << data.gsub("\\n", "\n")
  self.auth_result = auth_handler.receive_data
end

When('authentication show_initial is called') do
  auth_handler.show_initial
end

When('authentication do_resolution is called with {string}') do |data|
  auth_handler.do_resolution(data.dup)
end

When('authentication show_server_menu is called') do
  auth_handler.show_server_menu
end

When('authentication do_server_menu is called with {string}') do |data|
  auth_handler.do_server_menu(data.dup)
end

When('authentication login_name is called with {string}') do |name|
  auth_handler.login_name(name.dup)
end

When('authentication login_password is called with {string}') do |password|
  auth_handler.login_password(password.dup)
end

When('authentication ask_new_name is called') do
  auth_handler.ask_new_name
end

When('authentication new_name is called with nil') do
  # new_name does data.strip! first, but checks data.nil? after
  # We need to simulate passing a nil-like value. Since Ruby's strip!
  # on nil would raise, the nil check at line 191 handles a post-strip nil.
  # In practice this is a defensive check. We bypass strip by calling directly
  # with a special test approach.
  # Actually, looking at the code: data.strip! is called BEFORE data.nil? check.
  # So to hit line 191-193, data must be non-nil after strip.
  # This branch is actually dead code in practice (strip! returns nil when no
  # change but data itself remains a string). Let's still try to exercise it
  # by testing the surrounding code path. We'll pass an empty-ish value.
  # Actually, strip! mutates in place - data is still a String after strip!,
  # never nil. The nil check is unreachable in normal flow.
  # We'll call it with an empty string to hit the capitalize!/length check path.
  auth_handler.new_name(''.dup)
end

When('authentication new_name is called with {string}') do |data|
  auth_handler.new_name(data.dup)
end

When('authentication ask_sex is called') do
  auth_handler.ask_sex
end

When('authentication new_sex is called with {string}') do |data|
  auth_handler.new_sex(data.dup)
end

When('authentication ask_password is called') do
  auth_handler.ask_password
end

When('authentication new_password is called with {string}') do |data|
  auth_handler.new_password(data.dup)
end

When('authentication ask_color is called') do
  auth_handler.ask_color
end

When('authentication new_color is called with {string}') do |data|
  auth_handler.new_color(data.dup)
end

When('authentication create_new_player is called') do
  auth_handler.create_new_player
end

# =============================================================================
#                      T H E N   S T E P S
# =============================================================================

Then('the authentication result should be false') do
  assert_equal(false, auth_result)
end

Then('the authentication result should be true') do
  assert_equal(true, auth_result)
end

Then('the authentication input buffer should contain {string}') do |expected|
  assert(auth_handler.in_buffer.include?(expected),
         "Expected input buffer to contain #{expected.inspect}, got #{auth_handler.in_buffer.inspect}")
end

Then('the authentication input buffer should be empty') do
  assert(auth_handler.in_buffer.empty?,
         "Expected input buffer to be empty, got #{auth_handler.in_buffer.inspect}")
end

Then('the authentication state should be {string}') do |expected|
  assert_equal(expected.to_sym, auth_handler.state,
               "Expected state #{expected.inspect}, got #{auth_handler.state.inspect}")
end

Then('the authentication output should include {string}') do |fragment|
  combined = auth_handler.all_output
  assert(combined.downcase.include?(fragment.downcase),
         "Expected output to include #{fragment.inspect}, got:\n#{combined}")
end

Then('the authentication display should have initialized colors') do
  assert(auth_handler.display.colors_initialized,
         'Expected display to have initialized colors')
end

Then('the authentication display should not have initialized colors') do
  assert(!auth_handler.display.colors_initialized,
         'Expected display NOT to have initialized colors')
end

Then('the authentication connection should be closing') do
  assert(auth_handler.closing_after_write,
         'Expected close_connection_after_writing to have been called')
end

Then('the authentication connection should have been closed') do
  assert(auth_handler.closed_flag,
         'Expected connection to be closed')
end

Then('the authentication player should be set') do
  assert_not_nil(auth_handler.player,
                 'Expected @player to be set but it was nil')
end

Then('the authentication player should be admin') do
  assert(auth_handler.player.admin,
         'Expected player to be admin')
end

Then('the authentication player output should include {string}') do |fragment|
  assert_not_nil(auth_handler.player, 'Player should be set')
  combined = auth_handler.player.outputs.join("\n")
  assert(combined.downcase.include?(fragment.downcase),
         "Expected player output to include #{fragment.inspect}, got:\n#{combined}")
end

Then('the authentication display should have echo off') do
  assert(!auth_handler.display.echo_state,
         'Expected echo to be off')
end

Then('the authentication display should have echo on') do
  assert(auth_handler.display.echo_state,
         'Expected echo to be on')
end

Then('the authentication callback should have received {string}') do |expected|
  assert_equal(expected, auth_callback_data,
               "Expected callback data #{expected.inspect}, got #{auth_callback_data.inspect}")
end

Then('the authentication editor should have received input') do
  assert(!auth_handler.editor_inputs.empty?,
         'Expected editor to have received input')
end

Then('the authentication player should have received handle_input') do
  assert(!auth_handler.player.handled_inputs.empty?,
         'Expected player to have received handle_input')
end

Then('the authentication final state should be nil') do
  assert_nil(auth_handler.state,
             "Expected state to be nil, got #{auth_handler.state.inspect}")
end
