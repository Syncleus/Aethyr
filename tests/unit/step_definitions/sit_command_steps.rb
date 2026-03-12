# frozen_string_literal: true
###############################################################################
# Step definitions for SitCommand action coverage.                            #
#                                                                             #
#   • SRP  – Each step performs exactly one behavioural assertion.             #
#   • OCP  – Production code remains untouched; seams are light-weight doubles#
#   • LSP  – Test doubles honour the contracts expected by SitCommand.        #
#   • ISP  – Doubles implement *only* the interface actually exercised.       #
#   • DIP  – The concrete $manager global is replaced by a stub that conforms #
#            to the abstract dependency.                                       #
###############################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/sit'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module SitCommandWorld
  attr_accessor :sit_player, :sit_room, :sit_command, :sit_target_obj,
                :sit_manager_find_result
end
World(SitCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# A minimal player stub with the interface used by SitCommand.
class SitTestPlayer
  attr_accessor :container, :name, :room

  def initialize(name = 'TestPlayer')
    @name      = name
    @container = 'room_1'
    @room      = 'room_1'
    @outputs   = []
    @balanced  = true
    @sitting   = false
    @prone     = false
    @can_sit   = true
  end

  def output(message, _newline = true)
    @outputs << message
  end

  def outputs
    @outputs
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

  def prone?
    @prone
  end

  def set_prone(val)
    @prone = val
  end

  def set_can_sit(val)
    @can_sit = val
  end

  def sit(_object = nil)
    @can_sit
  end
end

# A minimal sittable object stub.
class SitTestObject
  attr_accessor :name, :generic, :sittable, :occupied, :has_room_val, :is_plural
  attr_reader :sat_on_by_players

  def initialize(name = 'chair')
    @name       = name
    @generic    = name
    @sittable   = false
    @occupied   = false
    @has_room_val = true
    @is_plural  = false
    @sat_on_by_players = []
  end

  def can?(ability)
    ability == :sittable? && @sittable
  end

  def occupied_by?(_player)
    @occupied
  end

  def has_room?
    @has_room_val
  end

  def plural?
    @is_plural
  end

  def sat_on_by(player)
    @sat_on_by_players << player
  end
end

# A minimal room stub that records events.
class SitTestRoom
  attr_reader :events, :output_calls

  def initialize
    @events       = []
    @output_calls = []
  end

  def out_event(event)
    @events << event
  end

  def output(event)
    @output_calls << event
  end
end

# A minimal manager stub.
class SitTestManager
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
Given('a stubbed SitCommand environment') do
  @sit_player  = SitTestPlayer.new('TestPlayer')
  @sit_room    = SitTestRoom.new
  @sit_target_obj = nil

  $manager = SitTestManager.new(@sit_room)
end

Given('the sit player is not balanced') do
  @sit_player.set_balance(false)
end

Given('the sit player is balanced') do
  @sit_player.set_balance(true)
end

Given('the sit player is already sitting') do
  @sit_player.set_sitting(true)
end

Given('the sit player is prone') do
  @sit_player.set_prone(true)
  @sit_player.set_sitting(false)
end

Given('the sit player is standing') do
  @sit_player.set_sitting(false)
  @sit_player.set_prone(false)
end

Given('the sit player can sit') do
  @sit_player.set_can_sit(true)
end

Given('the sit player cannot sit') do
  @sit_player.set_can_sit(false)
end

Given('the sit target object is not found') do
  $manager.find_result = nil
end

Given('the sit target object {string} is not sittable') do |name|
  @sit_target_obj = SitTestObject.new(name)
  @sit_target_obj.sittable = false
  $manager.find_result = @sit_target_obj
end

Given('the sit target object {string} is occupied by the player') do |name|
  @sit_target_obj = SitTestObject.new(name)
  @sit_target_obj.sittable = true
  @sit_target_obj.occupied = true
  $manager.find_result = @sit_target_obj
end

Given('the sit target object {string} has no room and is singular') do |name|
  @sit_target_obj = SitTestObject.new(name)
  @sit_target_obj.sittable = true
  @sit_target_obj.occupied = false
  @sit_target_obj.has_room_val = false
  @sit_target_obj.is_plural = false
  $manager.find_result = @sit_target_obj
end

Given('the sit target object {string} has no room and is plural') do |name|
  @sit_target_obj = SitTestObject.new(name)
  @sit_target_obj.sittable = true
  @sit_target_obj.occupied = false
  @sit_target_obj.has_room_val = false
  @sit_target_obj.is_plural = true
  $manager.find_result = @sit_target_obj
end

Given('the sit target object {string} is sittable with room') do |name|
  @sit_target_obj = SitTestObject.new(name)
  @sit_target_obj.sittable = true
  @sit_target_obj.occupied = false
  @sit_target_obj.has_room_val = true
  $manager.find_result = @sit_target_obj
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the SitCommand action is invoked with no object') do
  @sit_command = Aethyr::Core::Actions::Sit::SitCommand.new(@sit_player)
  @sit_command.action
end

When('the SitCommand action is invoked with object {string}') do |object_name|
  @sit_command = Aethyr::Core::Actions::Sit::SitCommand.new(@sit_player, object: object_name)
  @sit_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the sit player should see {string}') do |expected|
  assert(@sit_player.outputs.any? { |m| m.include?(expected) },
         "Expected player output to contain '#{expected}' but got: #{@sit_player.outputs.inspect}")
end

Then('the sit event to_player should be {string}') do |expected|
  value = @sit_command[:to_player]
  assert(value, 'to_player was not set on the event')
  assert_equal(expected, value,
               "Expected to_player to be '#{expected}' but got: #{value.inspect}")
end

Then('the sit event to_other should contain {string}') do |expected|
  value = @sit_command[:to_other]
  assert(value, 'to_other was not set on the event')
  assert(value.include?(expected),
         "Expected to_other to contain '#{expected}' but got: #{value.inspect}")
end

Then('the sit room should receive output') do
  assert(!@sit_room.output_calls.empty?,
         'Expected room.output to have been called but it was not')
end

Then('the sit room should receive out_event') do
  assert(!@sit_room.events.empty?,
         'Expected room.out_event to have been called but it was not')
end

Then('the sit object should record sat_on_by') do
  assert(!@sit_target_obj.sat_on_by_players.empty?,
         'Expected object.sat_on_by to have been called but it was not')
end
