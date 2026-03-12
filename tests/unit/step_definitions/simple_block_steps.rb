# frozen_string_literal: true
###############################################################################
# Step definitions for SimpleBlockCommand action coverage.                     #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/simple_block'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                         #
###############################################################################
module SimpleBlockWorld
  attr_accessor :block_player, :block_room, :block_command,
                :block_target_name, :block_weapon, :block_b_event,
                :block_attacker, :combat_ready, :combat_events,
                :rand_value
end
World(SimpleBlockWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# Mock weapon for blocking
class BlockMockWeapon
  attr_accessor :name, :generic, :goid

  def initialize(name = "shield", generic = "shield")
    @name    = name
    @generic = generic
    @goid    = "weapon_goid_1"
  end
end

# Mock target / attacker
class BlockMockTarget
  attr_accessor :name, :goid

  def initialize(name = "Enemy", goid = "enemy_goid_1")
    @name = name
    @goid = goid
  end
end

# Recording player double that captures output messages.
class BlockMockPlayer
  attr_accessor :container, :name, :goid, :last_target, :balance

  attr_reader :messages

  def initialize
    @container   = "room_goid_1"
    @name        = "TestPlayer"
    @goid        = "player_goid_1"
    @messages    = []
    @last_target = nil
    @balance     = true
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def pronoun(type)
    case type
    when :possessive then "his"
    else "he"
    end
  end
end

# Mock room that records out_event calls and can find targets
class BlockMockRoom
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

Given('a stubbed SimpleBlock environment') do
  @block_player  = BlockMockPlayer.new
  @block_room    = BlockMockRoom.new
  @block_weapon  = nil
  @block_target_name = nil
  @block_attacker = nil
  @combat_ready  = true
  @combat_events = []
  @rand_value    = 0.3

  # Build a stub manager
  room_ref   = @block_room
  player_ref = @block_player

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

Given('Combat is not ready') do
  @combat_ready = false
end

Given('Combat is ready') do
  @combat_ready = true
end

Given('the block player has no block weapon') do
  @block_weapon = nil
end

Given('the block player has a block weapon') do
  @block_weapon = BlockMockWeapon.new("iron shield", "shield")
end

Given('the block target is the player themselves') do
  @block_target_name = "myself"
  @block_room.register("myself", @block_player)
end

Given('the block target is {string}') do |target_name|
  @block_target_name = target_name
  @block_attacker = BlockMockTarget.new("Enemy", "enemy_goid_1")
  @block_room.register(target_name, @block_attacker)
end

Given('there is no block target') do
  @block_target_name = nil
end

Given('there are no blockable events for the target') do
  @combat_events = []
end

Given('there are no general blockable events') do
  @combat_events = []
end

Given('there are blockable events for the target') do
  @block_attacker ||= BlockMockTarget.new("Enemy", "enemy_goid_1")
  evt = Event.new(:Combat)
  evt.player = @block_attacker
  evt.target = @block_player
  evt.blockable = true
  @combat_events = [evt]
end

Given('the player has a last_target of {string}') do |target_name|
  @block_attacker = BlockMockTarget.new("Enemy", "enemy_goid_1")
  @block_room.register(target_name, @block_attacker)
  @block_player.last_target = target_name
end

Given('the player has no last_target') do
  @block_player.last_target = nil
  # Make sure room.find(nil) returns nil (it does by default since nothing is registered under nil)
end

Given('there are general blockable events with an attacker') do
  @block_attacker = BlockMockTarget.new("Attacker", "attacker_goid_1")
  evt = Event.new(:Combat)
  evt.player = @block_attacker
  evt.target = @block_player
  evt.blockable = true
  @combat_events = [evt]
end

Given('rand will return above 0.5') do
  @rand_value = 0.8
end

Given('rand will return at or below 0.5') do
  @rand_value = 0.3
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('the SimpleBlockCommand action is invoked') do
  # Set up Combat stubs based on scenario state
  combat_ready_val = @combat_ready
  combat_events_val = @combat_events

  ::Combat.define_singleton_method(:ready?) { |_player| combat_ready_val }
  ::Combat.define_singleton_method(:find_events) { |**_opts| combat_events_val }

  # Build the command data
  data = {}
  data[:target] = @block_target_name if @block_target_name

  @block_command = Aethyr::Core::Actions::SimpleBlock::SimpleBlockCommand.new(@block_player, **data)

  # Stub get_weapon on the command instance
  weapon_ref = @block_weapon
  @block_command.define_singleton_method(:get_weapon) { |_player, _type| weapon_ref }

  # Stub rand on the command instance to control the branch
  rand_val = @rand_value
  @block_command.define_singleton_method(:rand) { |*_args| rand_val }

  @block_command.action
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the block player should have no output') do
  assert(@block_player.messages.empty?,
    "Expected no player output, got: #{@block_player.messages.inspect}")
end

Then('the block player should see {string}') do |fragment|
  match = @block_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@block_player.messages.inspect}")
end

Then('the block event action should be :weapon_block') do
  assert_equal(:weapon_block, @combat_events[0][:action],
    "Expected b_event action to be :weapon_block")
end

Then('the block event to_other should contain {string}') do |fragment|
  value = @combat_events[0][:to_other].to_s
  assert(value.include?(fragment),
    "Expected b_event to_other containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the block event to_player on b_event should contain {string}') do |fragment|
  value = @combat_events[0][:to_player].to_s
  assert(value.include?(fragment),
    "Expected b_event to_player containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the block event to_target on b_event should contain {string}') do |fragment|
  value = @combat_events[0][:to_target].to_s
  assert(value.include?(fragment),
    "Expected b_event to_target containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the block command to_other should contain {string}') do |fragment|
  value = @block_command[:to_other].to_s
  assert(value.include?(fragment),
    "Expected command to_other containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the block command to_target should contain {string}') do |fragment|
  value = @block_command[:to_target].to_s
  assert(value.include?(fragment),
    "Expected command to_target containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the block command to_player should contain {string}') do |fragment|
  value = @block_command[:to_player].to_s
  assert(value.include?(fragment),
    "Expected command to_player containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the block player balance should be false') do
  assert_equal(false, @block_player.balance,
    "Expected player balance to be false")
end

Then('the block room should receive out_event') do
  assert(!@block_room.events.empty?,
    "Expected room to receive out_event, but it did not.")
end

Then('the block player last_target should be set to the attacker goid') do
  assert_equal(@block_attacker.goid, @block_player.last_target,
    "Expected player last_target to be #{@block_attacker.goid.inspect}, got: #{@block_player.last_target.inspect}")
end
