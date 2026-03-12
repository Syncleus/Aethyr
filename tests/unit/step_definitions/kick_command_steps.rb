# frozen_string_literal: true
###############################################################################
# Step definitions for KickCommand action coverage.                            #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/kick'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                         #
###############################################################################
module KickCommandWorld
  attr_accessor :kick_player, :kick_room, :kick_command,
                :kick_target_name, :kick_target_obj,
                :kick_combat_ready, :kick_combat_valid,
                :kick_future_events
end
World(KickCommandWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# Simple info object with in_combat flag
class KickMockInfo
  attr_accessor :in_combat

  def initialize
    @in_combat = false
  end
end

# Mock target
class KickMockTarget
  attr_accessor :name, :goid, :info

  def initialize(name = "Enemy", goid = "kick_enemy_goid_1")
    @name = name
    @goid = goid
    @info = KickMockInfo.new
  end
end

# Recording player double that captures output messages.
class KickMockPlayer
  attr_accessor :container, :name, :goid, :last_target, :balance, :info

  attr_reader :messages

  def initialize
    @container   = "kick_room_goid_1"
    @name        = "KickPlayer"
    @goid        = "kick_player_goid_1"
    @messages    = []
    @last_target = nil
    @balance     = true
    @info        = KickMockInfo.new
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
class KickMockRoom
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

Given('a stubbed Kick environment') do
  @kick_player       = KickMockPlayer.new
  @kick_room         = KickMockRoom.new
  @kick_target_name  = nil
  @kick_target_obj   = nil
  @kick_combat_ready = true
  @kick_combat_valid = true
  @kick_future_events = []

  # Build a stub manager
  room_ref   = @kick_room
  player_ref = @kick_player

  mgr = Object.new
  mgr.define_singleton_method(:get_object) do |goid|
    room_ref if goid == player_ref.container
  end
  $manager = mgr

  # Stub Combat as a top-level constant if not already defined
  unless defined?(::Combat)
    Object.const_set(:Combat, Module.new)
  end
end

Given('Kick Combat is not ready') do
  @kick_combat_ready = false
end

Given('Kick Combat is ready') do
  @kick_combat_ready = true
end

Given('there is no kick target') do
  @kick_target_name = nil
end

Given('the kick target is {string}') do |target_name|
  @kick_target_name = target_name
  @kick_target_obj  = KickMockTarget.new("Enemy", "kick_enemy_goid_1")
  @kick_room.register(target_name, @kick_target_obj)
end

Given('Kick Combat valid_target returns false') do
  @kick_combat_valid = false
end

Given('Kick Combat valid_target returns true') do
  @kick_combat_valid = true
end

Given('the kick player has no last_target') do
  @kick_player.last_target = nil
end

Given('the kick player has a last_target of {string}') do |target_name|
  @kick_target_obj = KickMockTarget.new("Enemy", "kick_enemy_goid_1")
  @kick_room.register(target_name, @kick_target_obj)
  @kick_player.last_target = target_name
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('the KickCommand action is invoked') do
  # Set up Combat stubs based on scenario state
  combat_ready_val = @kick_combat_ready
  combat_valid_val = @kick_combat_valid
  future_events    = @kick_future_events

  ::Combat.define_singleton_method(:ready?)       { |_player| combat_ready_val }
  ::Combat.define_singleton_method(:valid_target?) { |_player, _target| combat_valid_val }
  ::Combat.define_singleton_method(:future_event)  { |event| future_events << event }

  # Build the command data
  data = {}
  data[:target] = @kick_target_name if @kick_target_name

  @kick_command = Aethyr::Core::Actions::Kick::KickCommand.new(@kick_player, **data)
  @kick_command.action
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the kick player should have no output') do
  assert(@kick_player.messages.empty?,
    "Expected no player output, got: #{@kick_player.messages.inspect}")
end

Then('the kick player should see {string}') do |fragment|
  match = @kick_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected kick player output containing #{fragment.inspect}, got: #{@kick_player.messages.inspect}")
end

Then('the kick room should not receive out_event') do
  assert(@kick_room.events.empty?,
    "Expected room to have no events, got: #{@kick_room.events.inspect}")
end

Then('the kick room should receive out_event') do
  assert(!@kick_room.events.empty?,
    "Expected room to receive out_event, but it did not.")
end

Then('the kick player last_target should be set to the target goid') do
  assert_equal(@kick_target_obj.goid, @kick_player.last_target,
    "Expected player last_target to be #{@kick_target_obj.goid.inspect}, got: #{@kick_player.last_target.inspect}")
end

Then('the kick player balance should be false') do
  assert_equal(false, @kick_player.balance,
    "Expected player balance to be false")
end

Then('the kick player info in_combat should be true') do
  assert_equal(true, @kick_player.info.in_combat,
    "Expected player info.in_combat to be true")
end

Then('the kick target info in_combat should be true') do
  assert_equal(true, @kick_target_obj.info.in_combat,
    "Expected target info.in_combat to be true")
end

Then('the kick command action should be :martial_hit') do
  assert_equal(:martial_hit, @kick_command[:action],
    "Expected command action to be :martial_hit")
end

Then('the kick command combat_action should be :kick') do
  assert_equal(:kick, @kick_command[:combat_action],
    "Expected command combat_action to be :kick")
end

Then('the kick command blockable should be true') do
  assert_equal(true, @kick_command[:blockable],
    "Expected command blockable to be true")
end

Then('the kick command to_other should contain {string}') do |fragment|
  value = @kick_command[:to_other].to_s
  assert(value.include?(fragment),
    "Expected command to_other containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the kick command to_target should contain {string}') do |fragment|
  value = @kick_command[:to_target].to_s
  assert(value.include?(fragment),
    "Expected command to_target containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the kick command to_player should contain {string}') do |fragment|
  value = @kick_command[:to_player].to_s
  assert(value.include?(fragment),
    "Expected command to_player containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('Kick Combat future_event should have been called') do
  assert(!@kick_future_events.empty?,
    "Expected Combat.future_event to have been called, but it was not.")
end
