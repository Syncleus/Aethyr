# frozen_string_literal: true
###############################################################################
# Step definitions for SimpleDodgeCommand action coverage.                     #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/simple_dodge'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                         #
###############################################################################
module SimpleDodgeWorld
  attr_accessor :dodge_player, :dodge_room, :dodge_command,
                :dodge_target_name, :dodge_attacker,
                :dodge_combat_ready, :dodge_combat_events,
                :dodge_rand_value
end
World(SimpleDodgeWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# Mock target / attacker
class DodgeMockTarget
  attr_accessor :name, :goid

  def initialize(name = "Enemy", goid = "dodge_enemy_goid_1")
    @name = name
    @goid = goid
  end
end

# Recording player double that captures output messages.
class DodgeMockPlayer
  attr_accessor :container, :name, :goid, :last_target, :balance

  attr_reader :messages

  def initialize
    @container   = "dodge_room_goid_1"
    @name        = "DodgePlayer"
    @goid        = "dodge_player_goid_1"
    @messages    = []
    @last_target = nil
    @balance     = true
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Mock room that records out_event calls and can find targets
class DodgeMockRoom
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

Given('a stubbed SimpleDodge environment') do
  @dodge_player       = DodgeMockPlayer.new
  @dodge_room         = DodgeMockRoom.new
  @dodge_target_name  = nil
  @dodge_attacker     = nil
  @dodge_combat_ready = true
  @dodge_combat_events = []
  @dodge_rand_value   = 0.3

  # Build a stub manager
  room_ref   = @dodge_room
  player_ref = @dodge_player

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

Given('SimpleDodge Combat is not ready') do
  @dodge_combat_ready = false
end

Given('SimpleDodge Combat is ready') do
  @dodge_combat_ready = true
end

Given('the dodge target is the player themselves') do
  @dodge_target_name = "myself"
  @dodge_room.register("myself", @dodge_player)
end

Given('the dodge target is {string}') do |target_name|
  @dodge_target_name = target_name
  @dodge_attacker = DodgeMockTarget.new("Enemy", "dodge_enemy_goid_1")
  @dodge_room.register(target_name, @dodge_attacker)
end

Given('there is no dodge target') do
  @dodge_target_name = nil
end

Given('there are no dodge blockable events for the target') do
  @dodge_combat_events = []
end

Given('there are no general dodge blockable events') do
  @dodge_combat_events = []
end

Given('there are dodge blockable events for the target') do
  @dodge_attacker ||= DodgeMockTarget.new("Enemy", "dodge_enemy_goid_1")
  evt = Event.new(:Combat)
  evt.player = @dodge_attacker
  evt.target = @dodge_player
  evt.blockable = true
  @dodge_combat_events = [evt]
end

Given('the dodge player has a last_target of {string}') do |target_name|
  @dodge_attacker = DodgeMockTarget.new("Enemy", "dodge_enemy_goid_1")
  @dodge_room.register(target_name, @dodge_attacker)
  @dodge_player.last_target = target_name
end

Given('the dodge player has no last_target') do
  @dodge_player.last_target = nil
end

Given('there are general dodge blockable events with an attacker') do
  @dodge_attacker = DodgeMockTarget.new("Attacker", "dodge_attacker_goid_1")
  evt = Event.new(:Combat)
  evt.player = @dodge_attacker
  evt.target = @dodge_player
  evt.blockable = true
  @dodge_combat_events = [evt]
end

Given('dodge rand will return above 0.5') do
  @dodge_rand_value = 0.8
end

Given('dodge rand will return at or below 0.5') do
  @dodge_rand_value = 0.3
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('the SimpleDodgeCommand action is invoked') do
  # Set up Combat stubs based on scenario state
  combat_ready_val  = @dodge_combat_ready
  combat_events_val = @dodge_combat_events

  ::Combat.define_singleton_method(:ready?) { |_player| combat_ready_val }
  ::Combat.define_singleton_method(:find_events) { |**_opts| combat_events_val }

  # Build the command data
  data = {}
  data[:target] = @dodge_target_name if @dodge_target_name

  @dodge_command = Aethyr::Core::Actions::SimpleDodge::SimpleDodgeCommand.new(@dodge_player, **data)

  # Stub rand on the command instance to control the branch
  rand_val = @dodge_rand_value
  @dodge_command.define_singleton_method(:rand) { |*_args| rand_val }

  @dodge_command.action
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the dodge player should have no output') do
  assert(@dodge_player.messages.empty?,
    "Expected no player output, got: #{@dodge_player.messages.inspect}")
end

Then('the dodge player should see {string}') do |fragment|
  match = @dodge_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected dodge player output containing #{fragment.inspect}, got: #{@dodge_player.messages.inspect}")
end

Then('the dodge event action should be :martial_miss') do
  assert_equal(:martial_miss, @dodge_combat_events[0][:action],
    "Expected b_event action to be :martial_miss")
end

Then('the dodge event type should be :MartialCombat') do
  assert_equal(:MartialCombat, @dodge_combat_events[0][:type],
    "Expected b_event type to be :MartialCombat")
end

Then('the dodge event to_other on b_event should contain {string}') do |fragment|
  value = @dodge_combat_events[0][:to_other].to_s
  assert(value.include?(fragment),
    "Expected b_event to_other containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the dodge event to_player on b_event should contain {string}') do |fragment|
  value = @dodge_combat_events[0][:to_player].to_s
  assert(value.include?(fragment),
    "Expected b_event to_player containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the dodge event to_target on b_event should contain {string}') do |fragment|
  value = @dodge_combat_events[0][:to_target].to_s
  assert(value.include?(fragment),
    "Expected b_event to_target containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the dodge command to_other should contain {string}') do |fragment|
  value = @dodge_command[:to_other].to_s
  assert(value.include?(fragment),
    "Expected command to_other containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the dodge command to_target should contain {string}') do |fragment|
  value = @dodge_command[:to_target].to_s
  assert(value.include?(fragment),
    "Expected command to_target containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the dodge command to_player should contain {string}') do |fragment|
  value = @dodge_command[:to_player].to_s
  assert(value.include?(fragment),
    "Expected command to_player containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the dodge player balance should be false') do
  assert_equal(false, @dodge_player.balance,
    "Expected player balance to be false")
end

Then('the dodge room should receive out_event') do
  assert(!@dodge_room.events.empty?,
    "Expected room to receive out_event, but it did not.")
end

Then('the dodge player last_target should be set to the attacker goid') do
  assert_equal(@dodge_attacker.goid, @dodge_player.last_target,
    "Expected player last_target to be #{@dodge_attacker.goid.inspect}, got: #{@dodge_player.last_target.inspect}")
end
