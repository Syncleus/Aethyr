# frozen_string_literal: true
###############################################################################
# Step definitions for WriteCommand action coverage.                           #
#                                                                              #
# These steps exercise every branch of                                         #
# lib/aethyr/core/actions/commands/write.rb to achieve >97% line coverage.     #
#                                                                              #
# All collaborators (player, inventory objects) are stubbed to isolate the     #
# command logic under test.                                                    #
###############################################################################

require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/write'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                         #
###############################################################################
module WriteCommandWorld
  attr_accessor :write_player, :write_command, :write_object,
                :write_search_result, :write_editor_data,
                :write_editor_cancelled
end
World(WriteCommandWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# Minimal info double for writable check.
class WriteMockInfo
  attr_accessor :writable

  def initialize(writable)
    @writable = writable
  end
end

# Minimal inventory object double.
class WriteMockObject
  attr_accessor :name, :info, :readable_text

  def initialize(name:, writable:, readable_text: nil)
    @name          = name
    @info          = WriteMockInfo.new(writable)
    @readable_text = readable_text
  end
end

# Minimal player double that records output and supports search_inv and editor.
class WriteMockPlayer
  attr_reader :messages

  def initialize
    @messages          = []
    @search_results    = {}
    @editor_data       = nil
    @editor_cancelled  = false
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def register_search_result(target, result)
    @search_results[target] = result
  end

  def search_inv(target)
    @search_results[target]
  end

  def set_editor_data(data)
    @editor_data = data
    @editor_cancelled = false
  end

  def set_editor_cancelled
    @editor_data = nil
    @editor_cancelled = true
  end

  # Immediately invoke the callback with the queued data (or nil).
  def editor(_existing_text = [], _max_lines = 100, &block)
    block.call(@editor_data) if block
  end
end

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('a stubbed WriteCommand environment') do
  self.write_player           = WriteMockPlayer.new
  self.write_object           = nil
  self.write_search_result    = nil
  self.write_editor_data      = nil
  self.write_editor_cancelled = false
end

Given('the write target is not in the player inventory') do
  self.write_search_result = nil
  # search_inv will return nil for any target
end

Given('the write target is a non-writable object named {string}') do |name|
  self.write_object = WriteMockObject.new(name: name, writable: false)
  self.write_search_result = write_object
  write_player.register_search_result('test_target', write_object)
end

Given('the write target is a writable object named {string} with existing text') do |name|
  self.write_object = WriteMockObject.new(
    name: name,
    writable: true,
    readable_text: ["Some old text"]
  )
  self.write_search_result = write_object
  write_player.register_search_result('test_target', write_object)
end

Given('the write target is a writable object named {string} without existing text') do |name|
  self.write_object = WriteMockObject.new(
    name: name,
    writable: true,
    readable_text: nil
  )
  self.write_search_result = write_object
  write_player.register_search_result('test_target', write_object)
end

Given('the write editor will provide new text') do
  write_player.set_editor_data(["New written text"])
end

Given('the write editor will cancel') do
  write_player.set_editor_cancelled
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('the write command is invoked') do
  self.write_command = Aethyr::Core::Actions::Write::WriteCommand.new(
    write_player,
    player: write_player,
    target: 'test_target'
  )

  write_command.action
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the write player should see {string}') do |expected|
  assert(
    write_player.messages.any? { |m| m.include?(expected) },
    "Expected player output to contain '#{expected}' but got: #{write_player.messages.inspect}"
  )
end

Then('the write object readable text should be updated') do
  assert_not_nil(write_object, 'Expected a write object to exist')
  assert_equal(
    ["New written text"],
    write_object.readable_text,
    "Expected readable_text to be updated but got: #{write_object.readable_text.inspect}"
  )
end

Then('the write object readable text should not be updated') do
  assert_not_nil(write_object, 'Expected a write object to exist')
  assert_nil(
    write_object.readable_text,
    "Expected readable_text to remain nil but got: #{write_object.readable_text.inspect}"
  )
end
