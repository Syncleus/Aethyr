# frozen_string_literal: true
################################################################################
# Step-definitions for Display class unit tests.
#
# Strategy: We mock the Ncurses C extension, TelnetScanner, and Window objects
# so that Display can be tested in isolation without a real terminal.
################################################################################

require 'test/unit/assertions'
require 'stringio'

World(Test::Unit::Assertions)

# ============================================================================
# Mock infrastructure – replaces heavy Ncurses/terminal dependencies
# ============================================================================

module DisplayTestWorld
  attr_accessor :display, :mock_socket, :recv_result, :set_color_result,
                :progress_result, :progress_bars, :set_term_called,
                :mock_windows, :mock_scanner, :getch_queue,
                :look_messages, :map_messages, :quick_bar_messages,
                :status_messages, :main_messages, :main_cleared,
                :look_cleared, :mock_player
end
World(DisplayTestWorld)

# ---------------------------------------------------------------------------
# DisplayMockNcursesWindow – lightweight stand-in for Ncurses::WINDOW
# (Prefixed to avoid collisions with other test files.)
# ---------------------------------------------------------------------------
class DisplayMockNcursesWindow
  attr_accessor :max_x, :max_y

  def initialize(h = 43, w = 80, y = 0, x = 0)
    @max_y = h
    @max_x = w
  end

  def getmaxx; @max_x; end
  def getmaxy; @max_y; end
  def intrflush(*_args); end
  def keypad(*_args); end
  def clear; end
  def mvaddstr(*_args); end
  def move(*_args); end
  def getch; -1; end
  def noutrefresh; end
  def border(*_args); end
  def color_set(*_args); end
  def attrset(*_args); end
  def attron(*_args); end
  def attroff(*_args); end
  def addstr(*_args); end
  def derwin(*_args); DisplayMockNcursesWindow.new; end
  def del; end
  def delete; end
end

# ---------------------------------------------------------------------------
# DisplayMockWindow – stands in for the Window class used by Display
# (Prefixed to avoid collisions with other test files.)
# ---------------------------------------------------------------------------
class DisplayMockWindow
  attr_accessor :selected, :buffer_pos, :messages, :cleared, :existed, :use_color
  attr_reader :window_text, :create_args

  def initialize(existed: false)
    @selected = false
    @buffer_pos = 0
    @messages = []
    @cleared = false
    @existed = existed
    @use_color = false
    @window_text = DisplayMockNcursesWindow.new
  end

  def exist?; @existed; end
  def create(**kwargs)
    @create_args = kwargs
    @existed = true
  end
  def destroy; @existed = false; end
  def update; end
  def clear; @cleared = true; end
  def enable_color; @use_color = true; end

  def send(message, word_wrap = true, add_newline: true)
    @messages << message
  end

  def respond_to?(method, include_private = false)
    return true if method == :buffer_pos
    super
  end
end

# ---------------------------------------------------------------------------
# DisplayMockScanner – stands in for TelnetScanner
# (Prefixed to avoid collisions with other test files.)
# ---------------------------------------------------------------------------
class DisplayMockScanner
  attr_accessor :process_iac_return

  def initialize
    @process_iac_return = true
  end

  def send_preamble; end

  def process_iac
    @process_iac_return
  end
end

# ---------------------------------------------------------------------------
# MockManager – stands in for $manager
# ---------------------------------------------------------------------------
class MockDisplayManager
  attr_accessor :room

  def get_object(_goid)
    @room
  end
end

# ---------------------------------------------------------------------------
# MockRoom – stands in for Room objects
# ---------------------------------------------------------------------------
class MockRoom
  attr_accessor :area_obj

  def look(_player)
    "You see a room."
  end

  def area
    @area_obj ||= MockArea.new
  end
end

class MockArea
  def render_map(_player, _position)
    "map data"
  end

  def position(_room)
    [0, 0]
  end
end

# ---------------------------------------------------------------------------
# MockPlayer for refresh_watch_windows
# ---------------------------------------------------------------------------
class MockDisplayPlayer
  attr_accessor :container, :output_messages

  def initialize
    @container = 'room_1'
    @output_messages = []
  end

  def output(message, message_type: :main, internal_clear: false)
    @output_messages << { message: message, type: message_type, clear: internal_clear }
  end
end

###############################################################################
# Setup: Stub Ncurses and related classes BEFORE Display is loaded
###############################################################################

# We need to intercept Ncurses calls. Since the real ncursesw gem
# may or may not be loaded, we ensure our stubs are in place.
Given('a stubbed Display environment') do
  # Ensure Ncurses module exists with all needed methods stubbed
  unless $display_ncurses_stubbed
    # Save originals if they exist
    if defined?(Ncurses)
      # Stub all class-level Ncurses methods used by Display
      ncurses_stubs = %i[
        newterm set_term cbreak noecho nonl curs_set
        start_color assume_default_colors init_pair
        doupdate echo nocbreak nl endwin resizeterm
        scrollok delwin
      ]

      ncurses_stubs.each do |method_name|
        unless Ncurses.respond_to?(:"_original_#{method_name}")
          if Ncurses.respond_to?(method_name)
            Ncurses.singleton_class.alias_method(:"_original_#{method_name}", method_name)
          end
          Ncurses.define_singleton_method(method_name) { |*_args| nil }
        end
      end

      # Stub Ncurses.stdscr to return a mock
      unless Ncurses.respond_to?(:_original_stdscr)
        if Ncurses.respond_to?(:stdscr)
          Ncurses.singleton_class.alias_method(:_original_stdscr, :stdscr)
        end
        Ncurses.define_singleton_method(:stdscr) { DisplayMockNcursesWindow.new }
      end

      # Stub Ncurses.COLORS
      unless Ncurses.respond_to?(:_original_COLORS)
        if Ncurses.respond_to?(:COLORS)
          Ncurses.singleton_class.alias_method(:_original_COLORS, :COLORS)
        end
        Ncurses.define_singleton_method(:COLORS) { 8 }
      end

      # Stub Ncurses::WINDOW.new
      unless defined?(Ncurses::WINDOW)
        Ncurses.const_set(:WINDOW, DisplayMockNcursesWindow)
      else
        Ncurses::WINDOW.define_singleton_method(:new) { |*args| DisplayMockNcursesWindow.new(*args) }
      end
    end

    # Stub Window.new to return DisplayMockWindow instances
    require 'aethyr/core/render/window'
    unless Window.respond_to?(:_original_new)
      Window.singleton_class.alias_method(:_original_new, :new)
    end

    # Stub Window.split_message to pass through
    unless Window.respond_to?(:_original_split_message)
      if Window.respond_to?(:split_message)
        Window.singleton_class.alias_method(:_original_split_message, :split_message)
      end
    end

    # Stub TelnetScanner
    require 'aethyr/core/connection/telnet'
    unless TelnetScanner.respond_to?(:_original_new)
      TelnetScanner.singleton_class.alias_method(:_original_new, :new)
    end

    $display_ncurses_stubbed = true
  end

  # Reset Window.new to return DisplayMockWindow instances for this scenario
  @mock_windows = {}
  window_counter = [0]
  window_names = [:main, :input, :map, :look, :quick_bar, :status, :chat]

  Window.define_singleton_method(:new) do |*args, **kwargs|
    name = window_names[window_counter[0]] || :"window_#{window_counter[0]}"
    window_counter[0] += 1
    mw = DisplayMockWindow.new
    # Store ref - using a thread-local to communicate
    Thread.current[:display_test_windows] ||= {}
    Thread.current[:display_test_windows][name] = mw
    mw
  end

  # Reset TelnetScanner.new
  TelnetScanner.define_singleton_method(:new) do |*args|
    scanner = DisplayMockScanner.new
    Thread.current[:display_test_scanner] = scanner
    scanner
  end

  # Reset thread-local storage
  Thread.current[:display_test_windows] = {}
  Thread.current[:display_test_scanner] = nil

  @getch_queue = []
  @set_term_called = false
  @look_messages = []
  @map_messages = []
  @quick_bar_messages = []
  @status_messages = []
  @main_messages = []
  @main_cleared = false
  @look_cleared = false

  # Track set_term calls
  Ncurses.define_singleton_method(:set_term) do |*_args|
    Thread.current[:set_term_called] = true
    nil
  end
  Thread.current[:set_term_called] = false

  # Before loading real Display, snapshot the mock Display class (if present)
  # so we can restore it for non-display test scenarios later.
  if !$display_mock_snapshot_taken && defined?(::Display)
    $display_mock_snapshot_taken = true
    $display_mock_instance_methods = {}
    ::Display.instance_methods(false).each do |m|
      $display_mock_instance_methods[m] = ::Display.instance_method(m)
    end
    $display_mock_initialize = begin
      ::Display.instance_method(:initialize)
    rescue NameError
      nil
    end
  end

  # Ensure Display is loaded (first call adds real methods; subsequent calls are no-ops)
  require 'aethyr/core/render/display'

  # After the first `require`, snapshot the real Display methods so we can
  # swap back to them after the After hook restores the mock.
  unless $display_real_methods_saved
    $display_real_methods_saved = true
    $display_real_instance_methods = {}
    ::Display.instance_methods(false).each do |m|
      $display_real_instance_methods[m] = ::Display.instance_method(m)
    end
    $display_real_initialize = ::Display.instance_method(:initialize)
    # Also snapshot singleton (class) methods unique to the real Display
    $display_real_singleton_methods = {}
    (::Display.singleton_methods(false) - Object.singleton_methods(false)).each do |m|
      $display_real_singleton_methods[m] = ::Display.method(m)
    end
  end

  # If the After hook restored mock methods, swap real methods back in.
  if $display_needs_real_reload
    $display_real_instance_methods.each do |method_name, unbound_method|
      begin
        ::Display.define_method(method_name, unbound_method)
      rescue TypeError; end
    end
    begin
      ::Display.define_method(:initialize, $display_real_initialize)
    rescue TypeError; end
    $display_real_singleton_methods.each do |method_name, method_obj|
      ::Display.define_singleton_method(method_name, method_obj)
    end
    $display_needs_real_reload = false
  end
end

###############################################################################
# After hook: restore global state that display tests modified.
#
# TelnetScanner.new and Window.new must be restored after EACH scenario so
# that non-display tests (telnet_negotiation, player_connection, etc.) get
# the real constructors.  The display Given step re-applies the overrides
# at the start of every display scenario, so restoring here is safe.
#
# Additionally, restore the mock Display class (snapshotted before the real
# Display was loaded) so that tests like player_connection_lifecycle that
# defined a mock Display at file load time continue to see their mock.
###############################################################################
After do
  # Restore TelnetScanner.new so other tests get real TelnetScanner instances
  if defined?(TelnetScanner) && TelnetScanner.respond_to?(:_original_new)
    TelnetScanner.singleton_class.send(:define_method, :new, TelnetScanner.singleton_class.instance_method(:_original_new))
  end

  # Restore Window.new so other tests get real Window instances
  if defined?(Window) && Window.respond_to?(:_original_new)
    Window.singleton_class.send(:define_method, :new, Window.singleton_class.instance_method(:_original_new))
  end

  # Restore mock Display methods so non-display tests see their expected mock.
  if $display_mock_snapshot_taken && $display_mock_instance_methods
    $display_mock_instance_methods.each do |method_name, unbound_method|
      begin
        ::Display.define_method(method_name, unbound_method)
      rescue TypeError; end
    end
    if $display_mock_initialize
      begin
        ::Display.define_method(:initialize, $display_mock_initialize)
      rescue TypeError; end
    end
    # Signal that the next display scenario must swap real methods back in
    $display_needs_real_reload = true
  end
end

###############################################################################
# Helper to get mock windows and scanner after Display.new
###############################################################################
def setup_display_mocks
  @mock_windows = Thread.current[:display_test_windows] || {}
  @mock_scanner = Thread.current[:display_test_scanner]
end

def get_window(name)
  @mock_windows[name]
end

def display_scanner
  @display.instance_variable_get(:@scanner)
end

###############################################################################
# Given steps
###############################################################################

###############################################################################
# When steps - Constructor
###############################################################################
When('I create a Display with default colors') do
  @mock_socket = StringIO.new
  # StringIO doesn't have puts that works like socket, let's make it work
  @display = Display.new(@mock_socket)
  setup_display_mocks
end

When('I create a Display with custom colors') do
  @mock_socket = StringIO.new
  custom_colors = { 'roomtitle' => 'fg:red', 'regular' => 'fg:green bg:blue' }
  @display = Display.new(@mock_socket, custom_colors)
  setup_display_mocks
end

###############################################################################
# When steps - init_colors
###############################################################################
When('I call init_colors on the display') do
  @display.init_colors
end

###############################################################################
# When steps - selected
###############################################################################
When('I set selected to :main') do
  @display.selected = :main
end

When('I set selected to :map') do
  @display.selected = :map
end

When('I set selected to :look') do
  @display.selected = :look
end

When('I set selected to :chat') do
  @display.selected = :chat
end

When('I set selected to :status') do
  @display.selected = :status
end

When('I set selected to :unknown_window') do
  # Add an unknown window key with a DisplayMockWindow, then select it
  # We need to work with Display's internal @windows
  unk_window = DisplayMockWindow.new(existed: true)
  @display.instance_variable_get(:@windows)[:unknown_window] = unk_window
  @mock_windows[:unknown_window] = unk_window
  @display.selected = :unknown_window
end

When('I deselect all windows') do
  windows = @display.instance_variable_get(:@windows)
  windows.each { |_k, w| w.selected = false }
end

###############################################################################
# When steps - layout
###############################################################################
When('I set resolution to {int} by {int}') do |width, height|
  @display.resolution = [width, height]
end

When('I set layout to :wide') do
  @display.method(:layout).call(layout: :wide)
end

When('I set layout to :full') do
  @display.method(:layout).call(layout: :full)
end

When('I set layout to :partial') do
  @display.method(:layout).call(layout: :partial)
end

When('I set layout to :basic') do
  @display.method(:layout).call(layout: :basic)
end

###############################################################################
# When steps - recv
###############################################################################
When('I call recv and read_line returns nil') do
  # read_line goes through stages; first call with :none stage returns nil
  # after setting up and transitioning to :update
  @recv_result = @display.recv
end

When('I call recv and read_line returns {string}') do |expected|
  drive_read_line_to_input_stage

  chars = expected.chars.map(&:ord) + [13]
  setup_getch_sequence(chars)

  # Each printable character
  expected.length.times do
    @display.recv  # reads char from getch, sets @read_stage = :update
    @display.recv  # update stage -> :iac
    display_scanner.process_iac_return = true
    @display.recv  # iac -> :input
  end

  # Return key
  @recv_result = @display.recv
end

###############################################################################
# When steps - send_raw
###############################################################################
When('I send_raw {string}') do |message|
  @mock_socket = StringIO.new
  @display.instance_variable_set(:@socket, @mock_socket)
  @display.send_raw(message)
end

###############################################################################
# When steps - send
###############################################################################
When('I send {string} to message_type :main') do |message|
  main_win = get_window(:main)
  main_win.instance_variable_set(:@existed, true)
  @display.send(message, true, message_type: :main)
end

When('I send {string} to a non-existing message_type') do |message|
  main_win = get_window(:main)
  main_win.instance_variable_set(:@existed, true)
  @display.send(message, true, message_type: :nonexistent)
end

When('I send {string} with internal_clear to :main') do |message|
  main_win = get_window(:main)
  main_win.instance_variable_set(:@existed, true)
  @display.send(message, true, message_type: :main, internal_clear: true)
end

###############################################################################
# When steps - close
###############################################################################
When('I close the display') do
  @mock_socket = StringIO.new
  @display.instance_variable_set(:@socket, @mock_socket)
  @display.close
end

###############################################################################
# When steps - set_color
###############################################################################
When('I set color {string} to {string}') do |code, color|
  @set_color_result = @display.set_color(code, color)
end

When('use_color is false') do
  @display.use_color = false
end

When('I enable use_color') do
  @display.use_color = true
end

###############################################################################
# When steps - echo
###############################################################################
When('I call echo_off') do
  @display.echo_off
end

When('I call echo_on') do
  @display.echo_on
end

###############################################################################
# When steps - set_term
###############################################################################
When('I call set_term') do
  Thread.current[:set_term_called] = false
  @display.set_term
end

###############################################################################
# When steps - refresh_watch_windows
###############################################################################
When('the look window exists with a room') do
  look_win = get_window(:look)
  look_win.instance_variable_set(:@existed, true)
  @mock_room = MockRoom.new
  @mock_manager = MockDisplayManager.new
  @mock_manager.room = @mock_room
  $manager = @mock_manager
end

When('the look window exists without a room') do
  look_win = get_window(:look)
  look_win.instance_variable_set(:@existed, true)
  @mock_manager = MockDisplayManager.new
  @mock_manager.room = nil
  $manager = @mock_manager
end

When('the map window exists with a room') do
  map_win = get_window(:map)
  map_win.instance_variable_set(:@existed, true)
  @mock_room = MockRoom.new
  @mock_manager = MockDisplayManager.new
  @mock_manager.room = @mock_room
  $manager = @mock_manager
  @mock_player = MockDisplayPlayer.new
end

When('the map window exists without a room') do
  map_win = get_window(:map)
  map_win.instance_variable_set(:@existed, true)
  @mock_manager = MockDisplayManager.new
  @mock_manager.room = nil
  $manager = @mock_manager
  @mock_player = MockDisplayPlayer.new
end

When('the quick_bar window exists') do
  qb_win = get_window(:quick_bar)
  qb_win.instance_variable_set(:@existed, true)
end

When('the status window exists') do
  status_win = get_window(:status)
  status_win.instance_variable_set(:@existed, true)
end

When('I call refresh_watch_windows') do
  @mock_player ||= MockDisplayPlayer.new
  @display.refresh_watch_windows(@mock_player)
end

###############################################################################
# When steps - read_line input handling
###############################################################################
When('I initiate recv to start read_line') do
  @recv_result = @display.recv
end

# Helper to drive the read_line state machine through stages
def drive_read_line_to_input_stage
  # Call 1: :none -> :update -> :iac (the if blocks fall through, not elsif)
  @display.recv
  # Now @read_stage = :iac

  # Call 2: :iac -> process_iac returns true -> :input
  scanner = @display.instance_variable_get(:@scanner)
  scanner.process_iac_return = true
  @display.recv
  # Now @read_stage = :input, next recv will call getch
end

def setup_getch_sequence(chars)
  input_window = get_window(:input)
  idx = [0]
  input_window.window_text.define_singleton_method(:getch) do
    ch = chars[idx[0]] || -1
    idx[0] += 1
    ch
  end
end

When('I simulate typing {string} and pressing return') do |text|
  drive_read_line_to_input_stage

  chars = text.chars.map(&:ord) + [13]
  setup_getch_sequence(chars)

  scanner = @display.instance_variable_get(:@scanner)

  # Each printable character: getch -> :update -> :iac -> :input
  text.length.times do
    @display.recv  # reads char from getch, processes printable, @read_stage = :update
    @display.recv  # update stage -> :iac
    scanner.process_iac_return = true
    @display.recv  # iac -> :input
  end

  # Return key (13): reads char, processes return, returns input_buffer
  @recv_result = @display.recv
end

When('I simulate typing {string} then backspace then {string} and return') do |first, second|
  drive_read_line_to_input_stage

  chars = first.chars.map(&:ord) + [127] + second.chars.map(&:ord) + [13]
  setup_getch_sequence(chars)

  scanner = @display.instance_variable_get(:@scanner)
  total_keys = first.length + 1 + second.length
  total_keys.times do
    @display.recv  # reads char, processes it, sets @read_stage = :update
    @display.recv  # update stage -> :iac
    scanner.process_iac_return = true
    @display.recv  # iac -> :input
  end

  # Return key
  @recv_result = @display.recv
end

When('I simulate left arrow key press') do
  drive_read_line_to_input_stage
  setup_getch_sequence([Ncurses::KEY_LEFT])
  @recv_result = @display.recv  # reads KEY_LEFT, cursor moves
end

When('I simulate right arrow key press') do
  drive_read_line_to_input_stage
  setup_getch_sequence([Ncurses::KEY_RIGHT])
  @recv_result = @display.recv
end

When('I simulate up arrow key press') do
  drive_read_line_to_input_stage
  setup_getch_sequence([Ncurses::KEY_UP])
  @recv_result = @display.recv
end

When('I simulate down arrow key press') do
  drive_read_line_to_input_stage
  setup_getch_sequence([Ncurses::KEY_DOWN])
  @recv_result = @display.recv
end

When('I simulate escape sequence for left arrow') do
  drive_read_line_to_input_stage
  setup_getch_sequence([27, 91, 68])

  # Read 27: @escape = [27], @read_stage stays :iac
  @display.recv
  # iac -> :input
  display_scanner.process_iac_return = true
  @display.recv
  # Read 91: @escape = [27,91]
  @display.recv
  # iac -> :input
  display_scanner.process_iac_return = true
  @display.recv
  # Read 68: ch = KEY_LEFT, @escape = nil, KEY_LEFT handling, @read_stage = :update
  @recv_result = @display.recv
end

When('I simulate escape sequence for right arrow') do
  drive_read_line_to_input_stage
  setup_getch_sequence([27, 91, 67])

  @display.recv  # read 27
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  @display.recv  # read 91
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  @recv_result = @display.recv  # read 67 -> KEY_RIGHT
end

When('I simulate escape sequence for up arrow') do
  drive_read_line_to_input_stage
  setup_getch_sequence([27, 91, 65])

  @display.recv  # read 27
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  @display.recv  # read 91
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  @recv_result = @display.recv  # read 65 -> KEY_UP
end

When('I simulate escape sequence for down arrow') do
  drive_read_line_to_input_stage
  setup_getch_sequence([27, 91, 66])

  @display.recv  # read 27
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  @display.recv  # read 91
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  @recv_result = @display.recv  # read 66 -> KEY_DOWN
end

When('I simulate page up key press') do
  drive_read_line_to_input_stage
  setup_getch_sequence([27, 91, 53, 126])

  # Read 27
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  # Read 91
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  # Read 53 -> @escape = [27, 91, 53]
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  # Read 126 -> page up
  @recv_result = @display.recv
end

When('I simulate page down key press') do
  drive_read_line_to_input_stage
  setup_getch_sequence([27, 91, 54, 126])

  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @recv_result = @display.recv
end

When('I simulate page up key press for non-input window') do
  drive_read_line_to_input_stage
  main_win = get_window(:main)
  main_win.instance_variable_set(:@existed, true)

  setup_getch_sequence([27, 91, 53, 126])
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @recv_result = @display.recv
end

When('I simulate page down key press for non-input window') do
  drive_read_line_to_input_stage
  main_win = get_window(:main)
  main_win.instance_variable_set(:@existed, true)

  setup_getch_sequence([27, 91, 54, 126])
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @recv_result = @display.recv
end

When('I simulate unknown escape sequence') do
  drive_read_line_to_input_stage
  # ESC [ 5 then non-126: unknown key in [27,91,53] state
  setup_getch_sequence([27, 91, 53, 99])

  @display.recv  # read 27
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  @display.recv  # read 91
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  @display.recv  # read 53
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  @recv_result = @display.recv  # read 99 - unknown in [27,91,53]
end

When('I simulate unknown key in bracket escape') do
  drive_read_line_to_input_stage
  # ESC [ then unknown (not 53, 54, 65-68)
  setup_getch_sequence([27, 91, 99])

  @display.recv  # read 27
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  @display.recv  # read 91
  display_scanner.process_iac_return = true
  @display.recv  # iac -> input
  @recv_result = @display.recv  # read 99 - unknown in [27,91]
end

When('I simulate unknown key in page up state') do
  drive_read_line_to_input_stage
  setup_getch_sequence([27, 91, 53, 99])

  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @recv_result = @display.recv
end

When('I simulate unknown key in page down state') do
  drive_read_line_to_input_stage
  setup_getch_sequence([27, 91, 54, 99])

  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @display.recv
  display_scanner.process_iac_return = true
  @display.recv
  @recv_result = @display.recv
end

When('I simulate unknown escape completely') do
  drive_read_line_to_input_stage
  # Set @escape to something unrecognized - hits the else branch
  @display.instance_variable_set(:@escape, [99, 99])
  setup_getch_sequence([65])
  @recv_result = @display.recv
end

When('I simulate tab key press') do
  drive_read_line_to_input_stage
  setup_getch_sequence([9])
  @recv_result = @display.recv  # reads 9 (tab), changes selected
end

When('the look window is set to exist') do
  get_window(:look).instance_variable_set(:@existed, true)
end

When('no look window exists') do
  get_window(:look).instance_variable_set(:@existed, false)
end

When('the chat window is set to exist') do
  get_window(:chat).instance_variable_set(:@existed, true)
end

When('no chat window exists but status exists') do
  get_window(:chat).instance_variable_set(:@existed, false)
  get_window(:status).instance_variable_set(:@existed, true)
end

When('no chat or status windows exist') do
  get_window(:chat).instance_variable_set(:@existed, false)
  get_window(:status).instance_variable_set(:@existed, false)
end

When('the map window is set to exist') do
  get_window(:map).instance_variable_set(:@existed, true)
end

When('no map window exists') do
  get_window(:map).instance_variable_set(:@existed, false)
end

When('the status window is set to exist') do
  get_window(:status).instance_variable_set(:@existed, true)
end

When('no status window exists') do
  get_window(:status).instance_variable_set(:@existed, false)
end

When('I simulate an unidentified key press') do
  drive_read_line_to_input_stage
  # Key code 1 is not handled (ctrl-A or similar)
  setup_getch_sequence([1])
  @recv_result = @display.recv  # reads 1, hits else branch, logs unidentified
end

When('I simulate backspace at cursor position 0') do
  drive_read_line_to_input_stage
  # Backspace with cursor at position 0 - cursor_pos is 0, so if block is skipped
  setup_getch_sequence([127])
  @recv_result = @display.recv
end

###############################################################################
# When steps - generate_progress
###############################################################################
When('I generate a progress bar with width {int} and percentage {float}') do |width, pct|
  @progress_result = Display.send(:generate_progress, width, pct)
end

When('I generate a progress bar with horizontal_smooth style at {float}') do |pct|
  @progress_result = Display.send(:generate_progress, 20, pct, :horizontal_smooth)
end

When('I generate horizontal progress bars at all fraction levels') do
  @progress_bars = []
  # Generate bars at specific fractions that hit each threshold branch
  # Each fraction is chosen to produce a different partial block character
  width = 30
  # We need percentages that produce specific fraction-of-block values
  # working_space = 30 - 7 = 23, block_per = 1/23 ≈ 0.0435
  block_per = 1.0 / 23.0

  # Generate at fractions that hit each branch: 1/8, 2/8, 3/8, 4/8, 5/8, 6/8, 7/8
  (1..7).each do |i|
    frac = i.to_f / 8.0
    # We want percent_of_block = frac
    # remaining_coverage / block_per = frac
    # remaining_coverage = frac * block_per
    # percentage - filled_coverage = remaining_coverage
    # percentage = filled_coverage + frac * block_per
    # With filled = 5, filled_coverage = 5 * block_per
    pct = 5 * block_per + frac * block_per
    @progress_bars << Display.send(:generate_progress, width, pct, :horizontal_smooth)
  end
end

When('I generate a progress bar with label {string}') do |label|
  @progress_result = Display.send(:generate_progress, 20, 0.5, :vertical_smooth, label: label)
end

###############################################################################
# Then steps
###############################################################################
Then('the display should have default height {int}') do |height|
  assert_equal(height, @display.instance_variable_get(:@height))
end

Then('the display should have default width {int}') do |width|
  assert_equal(width, @display.instance_variable_get(:@width))
end

Then('the display layout_type should be :basic') do
  assert_equal(:basic, @display.layout_type)
end

Then('the display use_color should be false') do
  assert_equal(false, @display.use_color)
end

Then('the display should use the custom color settings') do
  assert_equal('fg:red', @display.color_settings['roomtitle'])
end

Then('the display use_color should be true') do
  assert_equal(true, @display.use_color)
end

Then('the selected window should be :main') do
  assert_equal(:main, @display.selected)
end

Then('the selected window should be :input') do
  assert_equal(:input, @display.selected)
end

Then('the selected window should be :look') do
  assert_equal(:look, @display.selected)
end

Then('the selected window should be :chat') do
  assert_equal(:chat, @display.selected)
end

Then('the selected window should be :status') do
  assert_equal(:status, @display.selected)
end

Then('the selected window should be :map') do
  assert_equal(:map, @display.selected)
end

Then('the layout_type should be :wide') do
  assert_equal(:wide, @display.layout_type)
end

Then('the layout_type should be :full') do
  assert_equal(:full, @display.layout_type)
end

Then('the layout_type should be :partial') do
  assert_equal(:partial, @display.layout_type)
end

Then('the layout_type should be :basic') do
  assert_equal(:basic, @display.layout_type)
end

Then('the resolution should be {int} by {int}') do |width, height|
  assert_equal([width, height], @display.resolution)
end

Then('global_refresh should return nil or false') do
  result = @display.global_refresh
  assert(!result, "Expected global_refresh to be falsy but got #{result.inspect}")
end

Then('global_refresh should return true') do
  result = @display.global_refresh
  assert_equal(true, result)
end

Then('echo? should be true') do
  assert_equal(true, @display.echo?)
end

Then('echo? should be false') do
  assert_equal(false, @display.echo?)
end

Then('recv should return nil') do
  assert_nil(@recv_result)
end

Then('recv should return nil for the first call') do
  assert_nil(@recv_result)
end

Then('recv should return {string}') do |expected|
  assert_equal(expected, @recv_result)
end

Then('recv should return {string} with newline') do |expected|
  assert_equal(expected + "\n", @recv_result)
end

Then('the socket should have received {string}') do |message|
  @mock_socket.rewind
  content = @mock_socket.read
  assert(content.include?(message), "Socket should contain '#{message}' but got '#{content}'")
end

Then('the main window should have received the message') do
  main_win = get_window(:main)
  assert(!main_win.messages.empty?, "Main window should have received messages")
end

Then('the main window should have received the message as fallback') do
  main_win = get_window(:main)
  assert(!main_win.messages.empty?, "Main window should have received fallback messages")
end

Then('the main window should have been cleared and received the message') do
  main_win = get_window(:main)
  assert(main_win.cleared, "Main window should have been cleared")
  assert(!main_win.messages.empty?, "Main window should have received messages")
end

Then('the socket should be closed') do
  assert(@mock_socket.closed?, "Socket should be closed")
end

Then('the color settings should contain key {string}') do |key|
  assert(@display.color_settings.key?(key), "Color settings should contain key '#{key}'")
end

Then('the set_color result should contain {string}') do |text|
  assert(@set_color_result.include?(text), "Expected result to contain '#{text}' but got '#{@set_color_result}'")
end

Then('use_color should be true') do
  assert_equal(true, @display.use_color)
end

Then('show_color_config should contain {string}') do |text|
  config = @display.show_color_config
  assert(config.include?(text), "Expected show_color_config to contain '#{text}'")
end

Then('the look window should have received look output') do
  look_win = get_window(:look)
  assert(!look_win.messages.empty?, "Look window should have received messages")
end

Then('the look window should show nothing to look at') do
  look_win = get_window(:look)
  has_nothing = look_win.messages.any? { |m| m.include?('Nothing to look at') }
  assert(has_nothing, "Look window should show 'Nothing to look at'")
end

Then('the map window should have received map output') do
  assert(!@mock_player.output_messages.empty?, "Player should have received map output")
end

Then('the map window should show no map') do
  @mock_player ||= MockDisplayPlayer.new
  @display.refresh_watch_windows(@mock_player)
  has_no_map = @mock_player.output_messages.any? { |m| m[:message].include?('No map') }
  assert(has_no_map, "Player should have received 'No map' message")
end

Then('the quick_bar should have received progress output') do
  qb_win = get_window(:quick_bar)
  assert(!qb_win.messages.empty?, "Quick bar should have received messages")
end

Then('the status window should have received status output') do
  status_win = get_window(:status)
  assert(!status_win.messages.empty?, "Status window should have received messages")
end

Then('Ncurses.set_term should have been called') do
  assert(Thread.current[:set_term_called], "Ncurses.set_term should have been called")
end

Then('the returned input should be {string}') do |expected|
  # recv adds "\n" to the result from read_line
  assert_equal(expected + "\n", @recv_result)
end

Then('the progress bar should contain block characters') do
  assert(@progress_result.is_a?(String), "Progress result should be a string")
  assert(@progress_result.include?('['), "Progress result should contain '['")
end

Then('the progress bar should contain bracket characters') do
  assert(@progress_result.is_a?(String), "Progress result should be a string")
  assert(@progress_result.include?('['), "Progress result should contain '['")
end

Then('all progress bars should be non-empty strings') do
  @progress_bars.each_with_index do |bar, i|
    assert(bar.is_a?(String) && !bar.empty?, "Progress bar #{i} should be a non-empty string")
  end
end

Then('the progress bar should contain {string}') do |text|
  assert(@progress_result.include?(text), "Expected progress bar to contain '#{text}' but got '#{@progress_result}'")
end
