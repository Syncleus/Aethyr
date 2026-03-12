# frozen_string_literal: true
###############################################################################
# Step definitions for ListenCommand action coverage.                         #
###############################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/listen'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module ListenCommandWorld
  attr_accessor :listen_player, :listen_room, :listen_command,
                :listen_player_messages, :listen_room_events
end
World(ListenCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Info stub that holds a sound attribute.
class ListenTestInfo
  attr_accessor :sound

  def initialize(sound = nil)
    @sound = sound
  end
end

# A minimal player stub with the interface used by ListenCommand.
class ListenTestPlayer
  attr_accessor :container, :name
  attr_reader :messages

  def initialize(name = 'ListenTestPlayer')
    @name      = name
    @container = 'listen_room_1'
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

# A minimal game object stub for listen targets.
class ListenTestObject
  attr_accessor :name, :info

  def initialize(name, sound = nil)
    @name = name
    @info = ListenTestInfo.new(sound)
  end

  def pronoun(type = nil)
    'It'
  end
end

# A minimal room stub that records events and can look up targets.
class ListenTestRoom
  attr_reader :events
  attr_accessor :info

  def initialize
    @events  = []
    @objects = {}
    @info    = ListenTestInfo.new(nil)
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
class ListenTestManager
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
Given('a stubbed ListenCommand environment') do
  @listen_player  = ListenTestPlayer.new('ListenTestPlayer')
  @listen_room    = ListenTestRoom.new
  $manager        = ListenTestManager.new(@listen_room)
  @listen_player_messages = @listen_player.messages
  @listen_room_events     = @listen_room.events
end

Given('the listen room has a sound {string}') do |sound_text|
  @listen_room.info.sound = sound_text
end

Given('the listen room has no sound') do
  @listen_room.info.sound = nil
end

Given('a listen target object {string} with no sound') do |name|
  obj = ListenTestObject.new(name, nil)
  @listen_room.register(name, obj)
end

Given('a listen target object {string} with sound {string}') do |name, sound_text|
  obj = ListenTestObject.new(name, sound_text)
  @listen_room.register(name, obj)
end

Given('a listen target object {string} with empty sound') do |name|
  obj = ListenTestObject.new(name, '')
  @listen_room.register(name, obj)
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the ListenCommand action is invoked with no target') do
  @listen_command = Aethyr::Core::Actions::Listen::ListenCommand.new(
    @listen_player, target: nil
  )
  @listen_command.action
end

When('the ListenCommand action is invoked targeting self') do
  # Make search_inv return the player so object == @player
  player_ref = @listen_player
  @listen_player.define_singleton_method(:search_inv) { |_name| player_ref }

  @listen_command = Aethyr::Core::Actions::Listen::ListenCommand.new(
    @listen_player, target: 'myself'
  )
  @listen_command.action
end

When('the ListenCommand action is invoked with target {string}') do |target_name|
  @listen_command = Aethyr::Core::Actions::Listen::ListenCommand.new(
    @listen_player, target: target_name
  )
  @listen_command.action
end

When('the ListenCommand action is invoked with unknown target {string}') do |target_name|
  @listen_command = Aethyr::Core::Actions::Listen::ListenCommand.new(
    @listen_player, target: target_name
  )
  @listen_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the listen event to_player should contain {string}') do |expected|
  value = @listen_command[:to_player]
  assert(value, 'to_player was not set on the event')
  assert(value.include?(expected),
         "Expected to_player to contain '#{expected}' but got: #{value.inspect}")
end

Then('the listen event to_other should contain {string}') do |expected|
  value = @listen_command[:to_other]
  assert(value, 'to_other was not set on the event')
  assert(value.include?(expected),
         "Expected to_other to contain '#{expected}' but got: #{value.inspect}")
end

Then('the listen event to_target should contain {string}') do |expected|
  value = @listen_command[:to_target]
  assert(value, 'to_target was not set on the event')
  assert(value.include?(expected),
         "Expected to_target to contain '#{expected}' but got: #{value.inspect}")
end

Then('the listen room should receive the event') do
  assert(!@listen_room_events.empty?,
         'Expected room.out_event to have been called but no events were recorded')
  assert_equal(@listen_command, @listen_room_events.last,
               'The last event sent to the room should be the ListenCommand itself')
end

Then('the listen player should see {string}') do |expected|
  match = @listen_player_messages.any? { |m| m.include?(expected) }
  assert(match,
         "Expected player output containing '#{expected}' but got: #{@listen_player_messages.inspect}")
end
