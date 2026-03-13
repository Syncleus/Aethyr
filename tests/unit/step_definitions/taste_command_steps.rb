# frozen_string_literal: true
###############################################################################
# Step definitions for TasteCommand action coverage.                          #
#                                                                             #
#   Covers lines 14-15, 17-22, 25-28, 30, 32-34 of                          #
#   lib/aethyr/core/actions/commands/taste.rb                                 #
###############################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/taste'

World(Test::Unit::Assertions)

###############################################################################
# Shared state for taste scenarios                                            #
###############################################################################
module TasteCommandWorld
  attr_accessor :taste_player, :taste_room, :taste_command,
                :taste_player_messages, :taste_room_events
end
World(TasteCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Info stub that holds a taste attribute.
class TasteTestInfo
  attr_accessor :taste

  def initialize(taste = nil)
    @taste = taste
  end
end

# A minimal player stub with the interface used by TasteCommand.
class TasteTestPlayer
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

# A minimal game object stub for taste targets.
class TasteTestObject
  attr_accessor :name, :info

  def initialize(name, taste = nil)
    @name = name
    @info = TasteTestInfo.new(taste)
  end

  def pronoun(_type = nil)
    'it'
  end
end

# A minimal room stub that records events and can look up targets.
class TasteTestRoom
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
class TasteTestManager
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
Given('a stubbed TasteCommand environment') do
  @taste_player  = TasteTestPlayer.new('TestPlayer')
  @taste_room    = TasteTestRoom.new
  $manager       = TasteTestManager.new(@taste_room)
  @taste_player_messages = @taste_player.messages
  @taste_room_events     = @taste_room.events
end

Given('the taste room contains the player as {string}') do |name|
  @taste_room.register(name, @taste_player)
end

Given('a taste target object {string} with no taste') do |name|
  obj = TasteTestObject.new(name, nil)
  @taste_room.register(name, obj)
end

Given('a taste target object {string} with taste {string}') do |name, taste_text|
  obj = TasteTestObject.new(name, taste_text)
  @taste_room.register(name, obj)
end

Given('a taste target object {string} with empty taste') do |name|
  obj = TasteTestObject.new(name, '')
  @taste_room.register(name, obj)
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the TasteCommand action is invoked with target {string}') do |target_name|
  @taste_command = Aethyr::Core::Actions::Taste::TasteCommand.new(
    @taste_player, target: target_name
  )
  @taste_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the taste event to_player should contain {string}') do |expected|
  value = @taste_command[:to_player]
  assert(value, 'to_player was not set on the event')
  assert(value.include?(expected),
         "Expected to_player to contain '#{expected}' but got: #{value.inspect}")
end

Then('the taste event to_other should contain {string}') do |expected|
  value = @taste_command[:to_other]
  assert(value, 'to_other was not set on the event')
  assert(value.include?(expected),
         "Expected to_other to contain '#{expected}' but got: #{value.inspect}")
end

Then('the taste event to_target should contain {string}') do |expected|
  value = @taste_command[:to_target]
  assert(value, 'to_target was not set on the event')
  assert(value.include?(expected),
         "Expected to_target to contain '#{expected}' but got: #{value.inspect}")
end

Then('the taste room should receive the event') do
  assert(!@taste_room_events.empty?,
         'Expected room.out_event to have been called but no events were recorded')
  assert_equal(@taste_command, @taste_room_events.last,
               'The last event sent to the room should be the TasteCommand itself')
end

Then('the taste player should see {string}') do |expected|
  match = @taste_player_messages.any? { |m| m.include?(expected) }
  assert(match,
         "Expected player output containing '#{expected}' but got: #{@taste_player_messages.inspect}")
end
