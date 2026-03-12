# frozen_string_literal: true
###############################################################################
# Step definitions for SmellCommand action coverage.                          #
#                                                                             #
#   • SRP  – Each step performs exactly one behavioural assertion.            #
#   • OCP  – Production code remains untouched; seams are light-weight       #
#            doubles.                                                         #
#   • LSP  – Test doubles honour the contracts expected by SmellCommand.     #
#   • ISP  – Doubles implement *only* the interface actually exercised.      #
#   • DIP  – The concrete $manager global is replaced by a stub that         #
#            conforms to the abstract «get_object» dependency.               #
###############################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/smell'

World(Test::Unit::Assertions)

###############################################################################
# Shared state for smell scenarios                                            #
###############################################################################
module SmellCommandWorld
  attr_accessor :smell_player, :smell_room, :smell_command,
                :smell_player_messages, :smell_room_events
end
World(SmellCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Info stub that holds a smell attribute.
class SmellTestInfo
  attr_accessor :smell

  def initialize(smell = nil)
    @smell = smell
  end
end

# A minimal player stub with the interface used by SmellCommand.
class SmellTestPlayer
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

# A minimal game object stub for smell targets.
class SmellTestObject
  attr_accessor :name, :info

  def initialize(name, smell = nil)
    @name = name
    @info = SmellTestInfo.new(smell)
  end

  def pronoun(type = nil)
    'It'
  end
end

# A minimal room stub that records events and can look up targets.
class SmellTestRoom
  attr_reader :events
  attr_accessor :info

  def initialize
    @events  = []
    @objects = {}
    @info    = SmellTestInfo.new(nil)
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
class SmellTestManager
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
Given('a stubbed SmellCommand environment') do
  @smell_player  = SmellTestPlayer.new('TestPlayer')
  @smell_room    = SmellTestRoom.new
  $manager       = SmellTestManager.new(@smell_room)
  @smell_player_messages = @smell_player.messages
  @smell_room_events     = @smell_room.events
end

Given('the smell room has a smell {string}') do |smell_text|
  @smell_room.info.smell = smell_text
end

Given('the smell room has no smell') do
  @smell_room.info.smell = nil
end

Given('a smell target object {string} with no smell') do |name|
  obj = SmellTestObject.new(name, nil)
  @smell_room.register(name, obj)
end

Given('a smell target object {string} with smell {string}') do |name, smell_text|
  obj = SmellTestObject.new(name, smell_text)
  @smell_room.register(name, obj)
end

Given('a smell target object {string} with empty smell') do |name|
  obj = SmellTestObject.new(name, '')
  @smell_room.register(name, obj)
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the SmellCommand action is invoked with no target') do
  @smell_command = Aethyr::Core::Actions::Smell::SmellCommand.new(
    @smell_player, target: nil
  )
  @smell_command.action
end

When('the SmellCommand action is invoked targeting self with high rand') do
  # Register player in room so room.find returns the player
  @smell_room.register('me', @smell_player)
  @smell_command = Aethyr::Core::Actions::Smell::SmellCommand.new(
    @smell_player, target: 'me'
  )
  # Stub rand to return > 0.6 so we hit the revolting stench branch
  @smell_command.define_singleton_method(:rand) { 0.7 }
  @smell_command.action
end

When('the SmellCommand action is invoked targeting self with low rand') do
  # Register player in room so room.find returns the player
  @smell_room.register('me', @smell_player)
  @smell_command = Aethyr::Core::Actions::Smell::SmellCommand.new(
    @smell_player, target: 'me'
  )
  # Stub rand to return <= 0.6 so we hit the "not too bad" branch
  @smell_command.define_singleton_method(:rand) { 0.5 }
  @smell_command.action
end

When('the SmellCommand action is invoked with unknown target {string}') do |target_name|
  @smell_command = Aethyr::Core::Actions::Smell::SmellCommand.new(
    @smell_player, target: target_name
  )
  @smell_command.action
end

When('the SmellCommand action is invoked with target {string}') do |target_name|
  @smell_command = Aethyr::Core::Actions::Smell::SmellCommand.new(
    @smell_player, target: target_name
  )
  @smell_command.action
end

When('the SmellCommand action is invoked with target {string} and low rand') do |target_name|
  @smell_room.register(target_name, @smell_player)
  @smell_command = Aethyr::Core::Actions::Smell::SmellCommand.new(
    @smell_player, target: target_name
  )
  @smell_command.define_singleton_method(:rand) { 0.5 }
  @smell_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the smell event to_player should contain {string}') do |expected|
  value = @smell_command[:to_player]
  assert(value, 'to_player was not set on the event')
  assert(value.include?(expected),
         "Expected to_player to contain '#{expected}' but got: #{value.inspect}")
end

Then('the smell event to_other should contain {string}') do |expected|
  value = @smell_command[:to_other]
  assert(value, 'to_other was not set on the event')
  assert(value.include?(expected),
         "Expected to_other to contain '#{expected}' but got: #{value.inspect}")
end

Then('the smell event to_target should contain {string}') do |expected|
  value = @smell_command[:to_target]
  assert(value, 'to_target was not set on the event')
  assert(value.include?(expected),
         "Expected to_target to contain '#{expected}' but got: #{value.inspect}")
end

Then('the smell room should receive the event') do
  assert(!@smell_room_events.empty?,
         'Expected room.out_event to have been called but no events were recorded')
  assert_equal(@smell_command, @smell_room_events.last,
               'The last event sent to the room should be the SmellCommand itself')
end

Then('the smell player should see {string}') do |expected|
  match = @smell_player_messages.any? { |m| m.include?(expected) }
  assert(match,
         "Expected player output containing '#{expected}' but got: #{@smell_player_messages.inspect}")
end
