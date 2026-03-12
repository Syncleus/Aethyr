# frozen_string_literal: true
###############################################################################
# Step definitions for PunchCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/punch'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module - scenario-scoped state                                         #
###############################################################################
module PunchCommandWorld
  attr_accessor :punch_player, :punch_room, :punch_command,
                :punch_target_obj, :punch_target_name,
                :punch_combat_ready, :punch_combat_valid,
                :punch_future_events
end
World(PunchCommandWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# Info object that tracks in_combat state
class PunchMockInfo
  attr_accessor :in_combat

  def initialize
    @in_combat = false
  end
end

# Mock target
class PunchMockTarget
  attr_accessor :name, :goid, :info

  def initialize(name = "Enemy", goid = "punch_enemy_goid_1")
    @name = name
    @goid = goid
    @info = PunchMockInfo.new
  end
end

# Recording player double that captures output messages.
class PunchMockPlayer
  attr_accessor :container, :name, :goid, :last_target, :balance, :info
  attr_reader :messages

  def initialize
    @container   = "punch_room_goid_1"
    @name        = "TestPuncher"
    @goid        = "punch_player_goid_1"
    @messages    = []
    @last_target = nil
    @balance     = true
    @info        = PunchMockInfo.new
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def pronoun(type)
    case type
    when :possessive then "his"
    when :subjective then "he"
    when :objective  then "him"
    else "his"
    end
  end
end

# Mock room that records out_event calls and can find targets
class PunchMockRoom
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

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('a stubbed PunchCommand environment') do
  @punch_player       = PunchMockPlayer.new
  @punch_room         = PunchMockRoom.new
  @punch_target_name  = nil
  @punch_target_obj   = nil
  @punch_combat_ready = true
  @punch_combat_valid = true
  @punch_future_events = []

  # Build a stub manager
  room_ref   = @punch_room
  player_ref = @punch_player

  mgr = Object.new
  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref
    end
  end
  $manager = mgr

  # Stub Combat as a top-level constant if not already defined
  unless defined?(::Combat)
    Object.const_set(:Combat, Module.new)
  end
end

Given('punch combat is not ready') do
  @punch_combat_ready = false
end

Given('punch combat is ready') do
  @punch_combat_ready = true
end

Given('the punch target is {string}') do |target_name|
  @punch_target_name = target_name
  @punch_target_obj = PunchMockTarget.new(target_name.capitalize, "punch_target_goid_1")
  @punch_room.register(target_name, @punch_target_obj)
end

Given('there is no punch target') do
  @punch_target_name = nil
end

Given('the punch player has no punch last_target') do
  @punch_player.last_target = nil
end

Given('the punch player punch last_target is {string}') do |target_name|
  @punch_target_obj = PunchMockTarget.new(target_name.capitalize, "punch_target_goid_1")
  @punch_room.register(target_name, @punch_target_obj)
  @punch_player.last_target = target_name
end

Given('punch combat valid_target returns false') do
  @punch_combat_valid = false
end

Given('punch combat valid_target returns true') do
  @punch_combat_valid = true
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('the PunchCommand action is invoked') do
  # Set up Combat stubs based on scenario state
  combat_ready_val = @punch_combat_ready
  combat_valid_val = @punch_combat_valid
  future_events_ref = @punch_future_events

  ::Combat.define_singleton_method(:ready?) { |_player| combat_ready_val }
  ::Combat.define_singleton_method(:valid_target?) { |_player, _target| combat_valid_val }
  ::Combat.define_singleton_method(:future_event) { |event| future_events_ref << event }

  # Build the command data
  data = {}
  data[:target] = @punch_target_name if @punch_target_name

  @punch_command = Aethyr::Core::Actions::Punch::PunchCommand.new(@punch_player, **data)
  @punch_command.action
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the punch player should have no output') do
  assert(@punch_player.messages.empty?,
    "Expected no punch player output, got: #{@punch_player.messages.inspect}")
end

Then('the punch player should see {string}') do |fragment|
  match = @punch_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected punch player output containing #{fragment.inspect}, got: #{@punch_player.messages.inspect}")
end

Then('the punch player should not see {string}') do |fragment|
  match = @punch_player.messages.any? { |m| m.include?(fragment) }
  assert(!match,
    "Expected punch player output NOT to contain #{fragment.inspect}, but got: #{@punch_player.messages.inspect}")
end

Then('the punch player last_target should be set to the punch target goid') do
  assert_equal(@punch_target_obj.goid, @punch_player.last_target,
    "Expected player last_target to be #{@punch_target_obj.goid.inspect}, got: #{@punch_player.last_target.inspect}")
end

Then('the punch command to_other should contain {string}') do |fragment|
  value = @punch_command[:to_other].to_s
  assert(value.include?(fragment),
    "Expected punch command to_other containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the punch command to_target should contain {string}') do |fragment|
  value = @punch_command[:to_target].to_s
  assert(value.include?(fragment),
    "Expected punch command to_target containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the punch command to_player should contain {string}') do |fragment|
  value = @punch_command[:to_player].to_s
  assert(value.include?(fragment),
    "Expected punch command to_player containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the punch command action should be :martial_hit') do
  assert_equal(:martial_hit, @punch_command[:action],
    "Expected punch command action to be :martial_hit, got: #{@punch_command[:action].inspect}")
end

Then('the punch command combat_action should be :punch') do
  assert_equal(:punch, @punch_command[:combat_action],
    "Expected punch command combat_action to be :punch, got: #{@punch_command[:combat_action].inspect}")
end

Then('the punch command blockable should be true') do
  assert_equal(true, @punch_command[:blockable],
    "Expected punch command blockable to be true, got: #{@punch_command[:blockable].inspect}")
end

Then('the punch player balance should be false') do
  assert_equal(false, @punch_player.balance,
    "Expected punch player balance to be false")
end

Then('the punch player should be in combat') do
  assert_equal(true, @punch_player.info.in_combat,
    "Expected punch player to be in combat")
end

Then('the punch target should be in combat') do
  assert_equal(true, @punch_target_obj.info.in_combat,
    "Expected punch target to be in combat")
end

Then('the punch room should have received out_event') do
  assert(!@punch_room.events.empty?,
    "Expected punch room to receive out_event, but it did not.")
end

Then('punch combat should have received future_event') do
  assert(!@punch_future_events.empty?,
    "Expected Combat.future_event to have been called, but it was not.")
end
