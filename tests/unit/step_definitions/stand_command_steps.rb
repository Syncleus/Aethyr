# frozen_string_literal: true
###############################################################################
# Step definitions for StandCommand action coverage.                          #
#                                                                             #
#   Covers all five branches in stand.rb:                                     #
#     1. Not prone        → "already on your feet"                            #
#     2. Prone, no balance → "cannot stand while unbalanced"                  #
#     3. Sitting, stand ok, object exists → evacuated_by called               #
#     4. Lying, stand ok, object nil      → no evacuated_by                   #
#     5. Stand fails       → "unable to stand up"                             #
###############################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/stand'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module StandCommandWorld
  attr_accessor :stand_player, :stand_room, :stand_command, :stand_object
end
World(StandCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Minimal player stub implementing the interface exercised by StandCommand.
class StandMockPlayer
  attr_accessor :container, :name, :sitting_on, :lying_on

  def initialize(name = 'TestPlayer')
    @name       = name
    @container  = 'room_1'
    @messages   = []
    @prone_val  = false
    @balanced   = true
    @sitting    = false
    @can_stand  = true
    @sitting_on = nil
    @lying_on   = nil
  end

  def output(message, _newline = true)
    @messages << message
  end

  def messages
    @messages
  end

  def prone?
    @prone_val
  end

  def set_prone(val)
    @prone_val = val
  end

  def balance
    @balanced
  end

  def set_balance(val)
    @balanced = val
  end

  def sitting?
    @sitting
  end

  def set_sitting(val)
    @sitting = val
  end

  def set_can_stand(val)
    @can_stand = val
  end

  def stand
    @can_stand
  end

  def pronoun
    'he'
  end
end

# Minimal room stub that records out_event calls.
class StandMockRoom
  attr_reader :events

  def initialize
    @events = []
  end

  def out_event(event)
    @events << event
  end
end

# Minimal object stub that records evacuated_by calls.
class StandMockObject
  attr_reader :evacuated_by_players

  def initialize
    @evacuated_by_players = []
  end

  def evacuated_by(player)
    @evacuated_by_players << player
  end
end

# Minimal manager stub wiring room and find.
class StandMockManager
  attr_accessor :room, :find_result

  def initialize(room)
    @room        = room
    @find_result = nil
  end

  def get_object(_container_id)
    @room
  end

  def find(_name, _context)
    @find_result
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################

Given('a stubbed StandCommand environment') do
  @stand_player = StandMockPlayer.new('TestPlayer')
  @stand_room   = StandMockRoom.new
  @stand_object = nil

  $manager = StandMockManager.new(@stand_room)
end

Given('the stand player is not prone') do
  @stand_player.set_prone(false)
end

Given('the stand player is prone') do
  @stand_player.set_prone(true)
end

Given('the stand player is balanced') do
  @stand_player.set_balance(true)
end

Given('the stand player is not balanced') do
  @stand_player.set_balance(false)
end

Given('the stand player is sitting on {string}') do |object_id|
  @stand_player.set_sitting(true)
  @stand_player.sitting_on = object_id
end

Given('the stand player is lying on {string}') do |object_id|
  @stand_player.set_sitting(false)
  @stand_player.lying_on = object_id
end

Given('the stand manager finds object {string} in room') do |_object_id|
  @stand_object = StandMockObject.new
  $manager.find_result = @stand_object
end

Given('the stand manager does not find any object') do
  @stand_object = nil
  $manager.find_result = nil
end

Given('the stand player can stand') do
  @stand_player.set_can_stand(true)
end

Given('the stand player cannot stand') do
  @stand_player.set_can_stand(false)
end

###############################################################################
# When steps                                                                  #
###############################################################################

When('the StandCommand action is invoked') do
  @stand_command = Aethyr::Core::Actions::Stand::StandCommand.new(@stand_player)
  @stand_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################

Then('the stand player should see {string}') do |expected|
  assert(@stand_player.messages.any? { |m| m.include?(expected) },
         "Expected player output to contain '#{expected}' but got: #{@stand_player.messages.inspect}")
end

Then('the stand event to_player should be {string}') do |expected|
  value = @stand_command[:to_player]
  assert(value, 'to_player was not set on the event')
  assert_equal(expected, value,
               "Expected to_player to be '#{expected}' but got: #{value.inspect}")
end

Then('the stand event to_other should be {string}') do |expected|
  value = @stand_command[:to_other]
  assert(value, 'to_other was not set on the event')
  assert_equal(expected, value,
               "Expected to_other to be '#{expected}' but got: #{value.inspect}")
end

Then('the stand event to_deaf_other should be {string}') do |expected|
  value = @stand_command[:to_deaf_other]
  assert(value, 'to_deaf_other was not set on the event')
  assert_equal(expected, value,
               "Expected to_deaf_other to be '#{expected}' but got: #{value.inspect}")
end

Then('the stand room should receive out_event') do
  assert(!@stand_room.events.empty?,
         'Expected room.out_event to have been called but it was not')
end

Then('the stand object should receive evacuated_by') do
  assert_not_nil(@stand_object, 'Expected an object to exist')
  assert(!@stand_object.evacuated_by_players.empty?,
         'Expected object.evacuated_by to have been called but it was not')
end

Then('the stand object should not receive evacuated_by') do
  if @stand_object
    assert(@stand_object.evacuated_by_players.empty?,
           'Expected object.evacuated_by NOT to have been called')
  end
  # If @stand_object is nil, the guard in source (unless object.nil?) ensures
  # evacuated_by was never called, which is the correct behaviour.
end
