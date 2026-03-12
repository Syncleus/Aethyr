# frozen_string_literal: true

###############################################################################
# Step definitions for window.feature                                         #
#                                                                             #
# Exercises every public method and branch in                                 #
#   lib/aethyr/core/render/window.rb                                          #
# using lightweight test doubles to avoid initializing a real ncurses screen.  #
###############################################################################

require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# WindowMockNcursesWindow – records method calls without needing a real
# terminal.  Prefixed with "Window" to avoid collisions with mock classes
# defined by other test files (e.g. display_steps.rb).
# ---------------------------------------------------------------------------
class WindowMockNcursesWindow
  attr_reader :calls, :max_y, :max_x

  def initialize(height = 20, width = 40, y = 0, x = 0)
    @max_y = height
    @max_x = width
    @calls = []
  end

  def getmaxy; @max_y; end
  def getmaxx; @max_x; end

  def derwin(h, w, y, x)
    @calls << [:derwin, h, w, y, x]
    WindowMockNcursesWindow.new(h, w, y, x)
  end

  def clear;           @calls << [:clear]; end
  def move(y, x);      @calls << [:move, y, x]; end
  def border(*args);   @calls << [:border, *args]; end
  def noutrefresh;     @calls << [:noutrefresh]; end
  def addstr(str);     @calls << [:addstr, str]; end
  def color_set(*a);   @calls << [:color_set, *a]; end
  def attrset(val);    @calls << [:attrset, val]; end
  def attron(val);     @calls << [:attron, val]; end
  def attroff(val);    @calls << [:attroff, val]; end
end

# ---------------------------------------------------------------------------
# Load the real ncursesw gem to get Ncurses constants (A_NORMAL, etc.).
# The Ncurses::WINDOW.new override and module-level stubs are applied in
# Before/After hooks to avoid polluting global state at file load time.
# ---------------------------------------------------------------------------
require 'ncursesw'

# Save the original Ncurses::WINDOW.new once at load time (before any
# hook can run) so we have a pristine copy to restore later.
unless Ncurses::WINDOW.respond_to?(:_window_test_original_new)
  class << Ncurses::WINDOW
    alias_method :_window_test_original_new, :new
  end
end

# ---------------------------------------------------------------------------
# Before hook: apply Ncurses stubs for window tests.
# After hook: restore originals so other test files are unaffected.
# ---------------------------------------------------------------------------
Before do
  # Override Ncurses::WINDOW.new to return our mock
  Ncurses::WINDOW.define_singleton_method(:new) do |height, width, y, x|
    WindowMockNcursesWindow.new(height, width, y, x)
  end

  # Stub module-level Ncurses methods that Window calls
  unless Ncurses.respond_to?(:_window_test_original_scrollok)
    if Ncurses.respond_to?(:scrollok)
      Ncurses.singleton_class.alias_method(:_window_test_original_scrollok, :scrollok)
    end
    Ncurses.define_singleton_method(:scrollok) { |*_args| nil }
  end

  unless Ncurses.respond_to?(:_window_test_original_delwin)
    if Ncurses.respond_to?(:delwin)
      Ncurses.singleton_class.alias_method(:_window_test_original_delwin, :delwin)
    end
    Ncurses.define_singleton_method(:delwin) { |*_args| nil }
  end

  # Ensure COLORS and COLOR_PAIR are available (Window class needs them)
  unless Ncurses.respond_to?(:COLORS)
    Ncurses.define_singleton_method(:COLORS) { 256 }
  end
  unless Ncurses.respond_to?(:COLOR_PAIR)
    Ncurses.define_singleton_method(:COLOR_PAIR) { |val| val }
  end
end

After do
  # Restore Ncurses::WINDOW.new to its original
  if Ncurses::WINDOW.respond_to?(:_window_test_original_new)
    Ncurses::WINDOW.singleton_class.send(:define_method, :new,
      Ncurses::WINDOW.singleton_class.instance_method(:_window_test_original_new))
  end
end

# ---------------------------------------------------------------------------
# Now load the Color module, FormatState, and Window class under test.
# ---------------------------------------------------------------------------
require 'aethyr/core/render/format'
require 'aethyr/core/render/window'

# ---------------------------------------------------------------------------
# World module – all mutable scenario state lives here.
# ---------------------------------------------------------------------------
module WindowWorld
  attr_accessor :window, :error_raised, :split_result, :wrap_result
end
World(WindowWorld)

# ---------------------------------------------------------------------------
# Color settings hash used across scenarios.
# ---------------------------------------------------------------------------
def default_color_settings
  {
    "regular" => "fg:white bg:black"
  }
end

# ---------------------------------------------------------------------------
# Helper: build a Window and inject mock ncurses windows via create.
# Since Ncurses::WINDOW.new is stubbed, create() works without a terminal.
# ---------------------------------------------------------------------------
def create_window_with_mocks(win, width: 40, height: 20, x: 0, y: 0)
  win.create(width: width, height: height, x: x, y: y)
end

###############################################################################
# Given steps                                                                 #
###############################################################################

Given('a non-buffered Window instance') do
  @window = Window.new(default_color_settings)
  @error_raised = nil
end

Given('a buffered Window instance') do
  @window = Window.new(default_color_settings, buffered: true)
  @error_raised = nil
end

Given('a buffered Window instance with buffer size {int}') do |size|
  @window = Window.new(default_color_settings, buffered: true, buffer_size: size)
  @error_raised = nil
end

Given('the buffer contains {string}') do |message|
  @window.instance_variable_get(:@buffer) << message
end

Given('a non-buffered Window instance with color enabled and window created') do
  @window = Window.new(default_color_settings)
  @error_raised = nil
  @window.enable_color
  create_window_with_mocks(@window)
end

Given('a buffered Window instance with color enabled and window created') do
  @window = Window.new(default_color_settings, buffered: true)
  @error_raised = nil
  @window.enable_color
  create_window_with_mocks(@window)
end

###############################################################################
# When steps – create / destroy / update                                      #
###############################################################################

When('the window is created with width {int} height {int} x {int} y {int}') do |w, h, x, y|
  @error_raised = nil
  begin
    create_window_with_mocks(@window, width: w, height: h, x: x, y: y)
  rescue => e
    @error_raised = e
  end
end

When('the window is destroyed') do
  @error_raised = nil
  begin
    @window.destroy
  rescue => e
    @error_raised = e
  end
end

When('the window is updated') do
  @error_raised = nil
  begin
    @window.update
  rescue => e
    @error_raised = e
  end
end

When('color is enabled on the window') do
  @window.enable_color
end

When('the window is selected') do
  @window.selected = true
end

When('the window is cleared') do
  @error_raised = nil
  begin
    @window.clear
  rescue => e
    @error_raised = e
  end
end

###############################################################################
# When steps – send                                                           #
###############################################################################

When('{string} is sent to the window') do |message|
  @error_raised = nil
  begin
    @window.send(message)
  rescue => e
    @error_raised = e
  end
end

When('{string} is sent to the window without newline') do |message|
  @error_raised = nil
  begin
    @window.send(message, true, add_newline: false)
  rescue => e
    @error_raised = e
  end
end

When('{int} messages are sent to the window') do |count|
  @error_raised = nil
  begin
    count.times { |i| @window.send("message #{i}") }
  rescue => e
    @error_raised = e
  end
end

###############################################################################
# When steps – buffer_pos                                                     #
###############################################################################

When('buffer_pos is set to {int}') do |pos|
  @error_raised = nil
  begin
    @window.buffer_pos = pos
  rescue => e
    @error_raised = e
  end
end

###############################################################################
# When steps – activate_color                                                 #
###############################################################################

When('activate_color is called with fg {int} and bg {int}') do |fg, bg|
  @error_raised = nil
  begin
    @window.activate_color(fg, bg)
  rescue => e
    @error_raised = e
  end
end

When('activate_color_window is called with color disabled') do
  @error_raised = nil
  begin
    # use_color is false, so activate_color_window should return early
    @window.__send__(:activate_color_window, @window.window_text, 15, 0)
  rescue => e
    @error_raised = e
  end
end

When('activate_color_window is called via color_set path') do
  @error_raised = nil
  begin
    # Ncurses may not have color_set by default; define it to exercise line 228
    unless Ncurses.respond_to?(:color_set)
      Ncurses.define_singleton_method(:color_set) { |*args| }
    end
    @window.__send__(:activate_color_window, @window.window_text, 15, 0)
  rescue => e
    @error_raised = e
  end
end

When('activate_color_window is called via attrset fallback path') do
  @error_raised = nil
  begin
    # Temporarily remove color_set so it falls back to attrset
    had_color_set = Ncurses.respond_to?(:color_set)
    if had_color_set
      saved_method = Ncurses.method(:color_set)
      Ncurses.singleton_class.send(:undef_method, :color_set)
    end

    @window.__send__(:activate_color_window, @window.window_text, 15, 0)

    # Restore color_set
    if had_color_set
      Ncurses.define_singleton_method(:color_set, saved_method)
    end
  rescue => e
    @error_raised = e
    # Still restore if error
    if defined?(had_color_set) && had_color_set && defined?(saved_method)
      Ncurses.define_singleton_method(:color_set, saved_method) rescue nil
    end
  end
end

###############################################################################
# When steps – class methods                                                  #
###############################################################################

When('split_message is called with the text {string} and cols {int}') do |message, cols|
  # Interpret escape sequences in the message
  interpreted = message.gsub("\\n", "\n").gsub("\\t", "\t").gsub("\\r", "\r")
  @split_result = Window.split_message(interpreted, cols)
end

When('word_wrap is called with the text {string} and cols {int}') do |line, cols|
  interpreted = line.gsub("\\n", "\n").gsub("\\t", "\t").gsub("\\r", "\r")
  @wrap_result = Window.word_wrap(interpreted, cols)
end

###############################################################################
# When steps – render (private, accessed via __send__)                        #
###############################################################################

When('render is called with {string} and add_newline true') do |message|
  @error_raised = nil
  begin
    @window.__send__(:render, message, add_newline: true)
  rescue => e
    @error_raised = e
  end
end

When('render is called with {string} and add_newline false') do |message|
  @error_raised = nil
  begin
    @window.__send__(:render, message, add_newline: false)
  rescue => e
    @error_raised = e
  end
end

###############################################################################
# Then steps – initialization                                                 #
###############################################################################

Then('the window should not be buffered') do
  assert_equal(false, @window.buffered)
end

Then('the window should be buffered') do
  assert_equal(true, @window.buffered)
end

Then('the window should not exist yet') do
  assert_equal(false, @window.exist?)
end

Then('the window should exist') do
  assert_equal(true, @window.exist?)
end

Then('the window should not use color') do
  assert_equal(false, @window.use_color)
end

Then('the window should use color') do
  assert_equal(true, @window.use_color)
end

Then('the window should not be selected') do
  assert_equal(false, @window.selected)
end

Then('the window buffer should be empty') do
  assert(@window.buffer.empty?, "Expected buffer to be empty")
end

Then('the window buffer_lines should be empty') do
  assert(@window.buffer_lines.empty?, "Expected buffer_lines to be empty")
end

Then('the window buffer_pos should be {int}') do |expected|
  assert_equal(expected, @window.buffer_pos)
end

Then('the window buffer_size should be {int}') do |expected|
  assert_equal(expected, @window.buffer_size)
end

###############################################################################
# Then steps – create                                                         #
###############################################################################

Then('creating the window with width {int} height {int} x {int} y {int} should raise {string}') do |w, h, x, y, msg|
  error = nil
  begin
    @window.create(width: w, height: h, x: x, y: y)
  rescue => e
    error = e
  end
  assert_not_nil(error, "Expected an error to be raised")
  assert(error.message.include?(msg), "Expected error '#{msg}' but got '#{error.message}'")
end

Then('the window width should be {int}') do |expected|
  assert_equal(expected, @window.width)
end

Then('the window height should be {int}') do |expected|
  assert_equal(expected, @window.height)
end

Then('the window x should be {int}') do |expected|
  assert_equal(expected, @window.x)
end

Then('the window y should be {int}') do |expected|
  assert_equal(expected, @window.y)
end

Then('the window_border should not be nil') do
  assert_not_nil(@window.window_border)
end

Then('the window_text should not be nil') do
  assert_not_nil(@window.window_text)
end

Then('the window_border should be nil') do
  assert_nil(@window.window_border)
end

Then('the window_text should be nil') do
  assert_nil(@window.window_text)
end

Then('the text_height should be a non-negative integer') do
  assert(@window.text_height >= 0, "Expected text_height >= 0")
end

Then('the text_width should be a non-negative integer') do
  assert(@window.text_width >= 0, "Expected text_width >= 0")
end

###############################################################################
# Then steps – generic                                                        #
###############################################################################

Then('no error should have been raised') do
  assert_nil(@error_raised, "Expected no error but got: #{@error_raised}")
end

###############################################################################
# Then steps – buffer                                                         #
###############################################################################

Then('the window buffer should contain {string}') do |expected|
  assert(@window.buffer.any? { |m| m.include?(expected) },
         "Expected buffer to contain '#{expected}' but buffer is: #{@window.buffer.inspect}")
end

Then('the window buffer length should not exceed twice {int}') do |max|
  # Each send adds message + possibly an empty string for newline, so buffer grows by 2
  effective_max = max
  assert(@window.buffer.length <= effective_max,
         "Expected buffer length <= #{effective_max} but got #{@window.buffer.length}")
end

###############################################################################
# Then steps – split_message                                                  #
###############################################################################

Then('the split result should have {int} line(s)') do |count|
  assert_equal(count, @split_result.length,
               "Expected #{count} lines but got #{@split_result.length}: #{@split_result.inspect}")
end

Then('the split result should have at least {int} line(s)') do |min|
  assert(@split_result.length >= min,
         "Expected at least #{min} lines but got #{@split_result.length}: #{@split_result.inspect}")
end

Then('split result line {int} should be {string}') do |idx, expected|
  assert_equal(expected, @split_result[idx],
               "Expected line #{idx} to be '#{expected}' but got '#{@split_result[idx]}'")
end

###############################################################################
# Then steps – word_wrap                                                      #
###############################################################################

Then('the wrap result should have {int} line(s)') do |count|
  assert_equal(count, @wrap_result.length,
               "Expected #{count} lines but got #{@wrap_result.length}: #{@wrap_result.inspect}")
end

Then('the wrap result should have at least {int} line(s)') do |min_count|
  assert(@wrap_result.length >= min_count,
         "Expected at least #{min_count} lines but got #{@wrap_result.length}: #{@wrap_result.inspect}")
end

Then('wrap result line {int} should be {string}') do |idx, expected|
  assert_equal(expected, @wrap_result[idx],
               "Expected line #{idx} to be '#{expected}' but got '#{@wrap_result[idx]}'")
end

###############################################################################
# Then steps – parse_buffer error                                             #
###############################################################################

Then('calling parse_buffer should raise {string}') do |msg|
  error = nil
  begin
    @window.__send__(:parse_buffer)
  rescue => e
    error = e
  end
  assert_not_nil(error, "Expected an error to be raised")
  assert(error.message.include?(msg), "Expected '#{msg}' but got '#{error.message}'")
end
