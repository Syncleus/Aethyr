# frozen_string_literal: true
################################################################################
# Step-definitions validating the Editor module from                            #
# lib/aethyr/core/render/editor.rb                                             #
#                                                                              #
# The Editor module is designed to be included in PlayerConnection. We create   #
# a lightweight test host class that includes Editor and provides all the       #
# method stubs the module depends on.                                          #
################################################################################

require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/render/editor'

World(Test::Unit::Assertions)

###############################################################################
# Shared world state                                                           #
###############################################################################
module EditorWorld
  attr_accessor :editor_host, :callback_result, :more_called
end
World(EditorWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# Minimal inventory stub
class EditorTestInventory
  def initialize
    @items = []
  end

  def remove(obj)
    @items.delete(obj)
  end

  def add(obj)
    @items << obj
  end

  def include?(obj)
    @items.include?(obj)
  end
end

# Minimal room/container stub
class EditorTestRoom
  attr_reader :inventory, :goid, :output_messages, :added_objects

  def initialize(goid = 'room_1')
    @goid = goid
    @inventory = EditorTestInventory.new
    @output_messages = []
    @added_objects = []
  end

  def output(message, *_args)
    @output_messages << message
  end

  def add(obj)
    @added_objects << obj
    @inventory.add(obj)
  end
end

# Minimal player info (OpenStruct-like)
class EditorTestInfo
  attr_accessor :former_room
end

# Minimal player stub
class EditorTestPlayer
  attr_accessor :container, :name, :info

  def initialize(name = 'TestPlayer')
    @name = name
    @container = 'room_1'
    @info = EditorTestInfo.new
  end

  def pronoun(type = :normal)
    case type
    when :possessive then 'his'
    else 'he'
    end
  end
end

# Minimal manager stub that returns rooms by goid
class EditorTestManager
  def initialize
    @objects = {}
  end

  def register(goid, obj)
    @objects[goid] = obj
  end

  def find(goid)
    @objects[goid]
  end
end

# The test host class that includes Editor and provides stubs for all
# methods the module calls on `self` (print, puts, send_puts, expect, more).
class EditorTestHost
  include Editor

  attr_accessor :player, :word_wrap, :editing, :editor_buffer,
                :editor_line, :editor_callback, :limit
  attr_reader :printed_output, :puts_output, :send_puts_output,
              :expect_callback_ref, :more_called

  def initialize(player)
    @player = player
    @word_wrap = 80
    @printed_output = []
    @puts_output = []
    @send_puts_output = []
    @expect_callback_ref = nil
    @more_called = false
  end

  # Stubs for methods that Editor calls on self
  def print(message, *_args)
    @printed_output << message.to_s
  end

  def puts(message = '', *_args)
    @puts_output << message.to_s
  end

  def send_puts(message, *_args)
    @send_puts_output << message.to_s
  end

  def expect(&block)
    @expect_callback_ref = block
  end

  def more
    @more_called = true
    "more output"
  end

  # Provide access to the internal expect callback so tests can invoke it
  def trigger_expect(input)
    @expect_callback_ref.call(input) if @expect_callback_ref
  end

  # Reset output buffers between interactions
  def clear_output
    @printed_output.clear
    @puts_output.clear
    @send_puts_output.clear
  end
end

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('a stubbed Editor environment') do
  @editor_room = EditorTestRoom.new('room_1')
  @editor_player = EditorTestPlayer.new('TestPlayer')
  @editor_player.container = @editor_room.goid

  @editor_manager = EditorTestManager.new
  @editor_manager.register('room_1', @editor_room)
  @editor_room.inventory.add(@editor_player)

  $manager = @editor_manager

  @editor_host = EditorTestHost.new(@editor_player)
  @callback_result = :not_called
  @more_called = false
end

Given('the editor has been started') do
  @callback_result = :not_called
  @editor_host.start_editor([], 100) do |result|
    @callback_result = result
  end
  @editor_host.clear_output

  # Re-register the room for fix_player
  @fix_room = EditorTestRoom.new('room_1')
  @editor_manager.register('room_1', @fix_room)
end

Given('the editor has been started with buffer {string}') do |buf|
  @callback_result = :not_called
  @editor_host.start_editor(buf.split(","), 100) do |result|
    @callback_result = result
  end
  @editor_host.clear_output

  @fix_room = EditorTestRoom.new('room_1')
  @editor_manager.register('room_1', @fix_room)
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('the editor is started with an empty array buffer') do
  @callback_result = :not_called
  @editor_host.start_editor([], 100) do |result|
    @callback_result = result
  end
end

When('the editor is started with array buffer {string}') do |csv|
  @callback_result = :not_called
  items = csv.split(",")
  @editor_host.start_editor(items, 100) do |result|
    @callback_result = result
  end
  @editor_host.clear_output

  @fix_room = EditorTestRoom.new('room_1')
  @editor_manager.register('room_1', @fix_room)
end

When('the editor is started with string buffer {string}') do |str|
  # Replace literal \n with actual newlines
  actual = str.gsub("\\n", "\n")
  @callback_result = :not_called
  @editor_host.start_editor(actual, 100) do |result|
    @callback_result = result
  end
end

When('the editor is started with limit {int}') do |limit|
  @callback_result = :not_called
  @editor_host.start_editor([], limit) do |result|
    @callback_result = result
  end
end

When('editor_prompt is called') do
  @editor_host.clear_output
  @editor_host.editor_prompt
end

When('editor_out is called with {string}') do |message|
  @editor_host.clear_output
  @editor_host.editor_out(message)
end

When('editor_echo is called') do
  @editor_host.clear_output
  @editor_host.editor_echo
end

When('editor_append is called with {string}') do |text|
  @editor_host.editor_append(text)
end

When('editor_input receives {string}') do |input|
  @editor_host.editor_input(input)
end

When('editor_help is called with {string}') do |command|
  @editor_host.clear_output
  @editor_host.editor_help(command)
end

When('editor_help is called with nil') do
  @editor_host.clear_output
  @editor_host.editor_help(nil)
end

When('editor_replace is called with line {int} and data {string}') do |line, data|
  @editor_host.clear_output
  @editor_host.editor_replace(line, data)
end

When('editor_delete is called with line {int}') do |line|
  @editor_host.clear_output
  @editor_host.editor_delete(line)
end

When('the editor line is set to {int}') do |n|
  @editor_host.editor_line = n
end

When('editor_go is called with line {int}') do |line|
  @editor_host.clear_output
  @editor_host.editor_go(line)
end

When('editor_clear is called') do
  @editor_host.clear_output
  @editor_host.editor_clear
end

When('editor_quit is called') do
  @editor_host.clear_output
  @editor_host.editor_quit
end

When('the expect callback receives {string}') do |input|
  @editor_host.clear_output
  @editor_host.trigger_expect(input)
end

When('editor_save is called') do
  @editor_host.clear_output
  @editor_host.editor_save
end

When('editor_really_quit is called') do
  @editor_host.clear_output
  @editor_host.editor_really_quit
end

When('fix_player is called') do
  @fix_room = EditorTestRoom.new('room_1')
  @editor_manager.register('room_1', @fix_room)
  @editor_host.fix_player
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the editor line should be {int}') do |expected|
  assert_equal(expected, @editor_host.editor_line,
               "Expected editor_line to be #{expected} but got #{@editor_host.editor_line}")
end

Then('the editor buffer should be empty') do
  assert(@editor_host.editor_buffer.empty?,
         "Expected editor buffer to be empty but got: #{@editor_host.editor_buffer.inspect}")
end

Then('editing should be true') do
  assert_equal(true, @editor_host.editing, "Expected editing to be true")
end

Then('editing should be false') do
  assert_equal(false, @editor_host.editing, "Expected editing to be false")
end

Then('the player should be removed from the room') do
  assert_nil(@editor_player.container,
             "Expected player.container to be nil after starting editor")
end

Then('the editor buffer should have {int} lines') do |count|
  assert_equal(count, @editor_host.editor_buffer.length,
               "Expected #{count} lines but got #{@editor_host.editor_buffer.length}")
end

Then('the editor limit should be {int}') do |expected|
  assert_equal(expected, @editor_host.limit,
               "Expected limit to be #{expected} but got #{@editor_host.limit}")
end

Then('the printed output should contain {string}') do |expected|
  all = @editor_host.printed_output.join(" ")
  assert(all.include?(expected),
         "Expected printed output to contain '#{expected}' but got: #{all.inspect}")
end

Then('the send_puts output should contain {string}') do |expected|
  all = @editor_host.send_puts_output.join(" ")
  assert(all.include?(expected),
         "Expected send_puts output to contain '#{expected}' but got: #{all.inspect}")
end

Then('the puts output should contain {string}') do |expected|
  all = @editor_host.puts_output.join(" ")
  assert(all.include?(expected),
         "Expected puts output to contain '#{expected}' but got: #{all.inspect}")
end

Then('the editor buffer should contain {string}') do |expected|
  assert(@editor_host.editor_buffer.include?(expected),
         "Expected buffer to contain '#{expected}' but got: #{@editor_host.editor_buffer.inspect}")
end

Then('the editor buffer should not contain {string}') do |expected|
  assert(!@editor_host.editor_buffer.include?(expected),
         "Expected buffer NOT to contain '#{expected}' but got: #{@editor_host.editor_buffer.inspect}")
end

Then('the more method should have been called') do
  assert(@editor_host.more_called,
         "Expected the more method to have been called")
end

Then('the callback result should not be nil') do
  assert(@callback_result != nil && @callback_result != :not_called,
         "Expected callback result to not be nil but got: #{@callback_result.inspect}")
end

Then('the callback result should be nil') do
  assert_nil(@callback_result,
             "Expected callback result to be nil but got: #{@callback_result.inspect}")
end

Then('the editor buffer should be nil') do
  assert_nil(@editor_host.editor_buffer,
             "Expected editor buffer to be nil but got: #{@editor_host.editor_buffer.inspect}")
end

Then('the editor callback should be nil') do
  assert_nil(@editor_host.editor_callback,
             "Expected editor callback to be nil but got: #{@editor_host.editor_callback.inspect}")
end

Then('the player should be back in the room') do
  assert(@fix_room.added_objects.include?(@editor_player),
         "Expected player to have been added back to the room")
end
