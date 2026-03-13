# frozen_string_literal: true
###############################################################################
# Step definitions for FeelCommand action coverage.                           #
###############################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/feel'

World(Test::Unit::Assertions)

###############################################################################
# Shared state for feel scenarios                                             #
###############################################################################
module FeelCommandWorld
  attr_accessor :feel_player, :feel_room, :feel_command,
                :feel_player_messages, :feel_room_events
end
World(FeelCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Info stub that holds a texture attribute.
class FeelTestInfo
  attr_accessor :texture

  def initialize(texture = nil)
    @texture = texture
  end
end

# A minimal player stub with the interface used by FeelCommand.
class FeelTestPlayer
  attr_accessor :container, :name
  attr_reader :messages

  def initialize(name = 'TestPlayer')
    @name      = name
    @container = 'room_1'
    @messages  = []
  end

  def output(message, _newline = true)
    @messages << message.to_s
  end

  def pronoun(type = nil)
    case type
    when :possessive then 'his'
    else 'he'
    end
  end

  def search_inv(_name)
    nil
  end
end

# A minimal game object stub for feel targets.
class FeelTestObject
  attr_accessor :name, :info

  def initialize(name, texture = nil)
    @name = name
    @info = FeelTestInfo.new(texture)
  end

  def pronoun(type = nil)
    case type
    when :possessive then 'its'
    else 'it'
    end
  end
end

# A minimal room stub that records events and can look up targets.
class FeelTestRoom
  attr_reader :events

  def initialize
    @events  = []
    @objects = {}
  end

  def register(name, obj)
    @objects[name] = obj
  end

  def find(name)
    @objects[name]
  end

  def out_event(event)
    @events << event
  end
end

# A minimal manager stub that returns a room for get_object.
class FeelTestManager
  attr_accessor :room

  def initialize(room)
    @room = room
  end

  def get_object(_container_id)
    @room
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed FeelCommand environment') do
  @feel_player  = FeelTestPlayer.new('TestPlayer')
  @feel_room    = FeelTestRoom.new
  $manager      = FeelTestManager.new(@feel_room)
  @feel_player_messages = @feel_player.messages
  @feel_room_events     = @feel_room.events
end

Given('a feel target object {string} with no texture') do |name|
  obj = FeelTestObject.new(name, nil)
  @feel_room.register(name, obj)
end

Given('a feel target object {string} with texture {string}') do |name, texture_text|
  obj = FeelTestObject.new(name, texture_text)
  @feel_room.register(name, obj)
end

Given('a feel target object {string} with empty texture') do |name|
  obj = FeelTestObject.new(name, '')
  @feel_room.register(name, obj)
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the FeelCommand action is invoked with target {string}') do |target_name|
  @feel_command = Aethyr::Core::Actions::Feel::FeelCommand.new(
    @feel_player, target: target_name
  )
  @feel_command.action
end

When('the FeelCommand action is invoked with unknown target {string}') do |target_name|
  @feel_command = Aethyr::Core::Actions::Feel::FeelCommand.new(
    @feel_player, target: target_name
  )
  @feel_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the feel event to_player should contain {string}') do |expected|
  value = @feel_command[:to_player]
  assert(value, 'to_player was not set on the event')
  assert(value.include?(expected),
         "Expected to_player to contain '#{expected}' but got: #{value.inspect}")
end

Then('the feel event to_other should contain {string}') do |expected|
  value = @feel_command[:to_other]
  assert(value, 'to_other was not set on the event')
  assert(value.include?(expected),
         "Expected to_other to contain '#{expected}' but got: #{value.inspect}")
end

Then('the feel event to_target should contain {string}') do |expected|
  value = @feel_command[:to_target]
  assert(value, 'to_target was not set on the event')
  assert(value.include?(expected),
         "Expected to_target to contain '#{expected}' but got: #{value.inspect}")
end

Then('the feel room should receive the event') do
  assert(!@feel_room_events.empty?,
         'Expected room.out_event to have been called but no events were recorded')
  assert_equal(@feel_command, @feel_room_events.last,
               'The last event sent to the room should be the FeelCommand itself')
end

Then('the feel player should see {string}') do |expected|
  match = @feel_player_messages.any? { |m| m.include?(expected) }
  assert(match,
         "Expected player output containing '#{expected}' but got: #{@feel_player_messages.inspect}")
end
