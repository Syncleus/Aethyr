# frozen_string_literal: true
###############################################################################
# Step definitions for SlashCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/slash'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                         #
###############################################################################
module SlashWorld
  attr_accessor :slash_player, :slash_room, :slash_command,
                :slash_target_obj, :slash_weapon, :slash_target_name,
                :slash_combat_ready, :slash_combat_valid,
                :slash_future_events
end
World(SlashWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# Info object that tracks in_combat state
class SlashMockInfo
  attr_accessor :in_combat

  def initialize
    @in_combat = false
  end
end

# Mock weapon for slashing
class SlashMockWeapon
  attr_accessor :name, :generic, :goid

  def initialize(name = "sword", generic = "sword")
    @name    = name
    @generic = generic
    @goid    = "slash_weapon_goid_1"
  end
end

# Mock target
class SlashMockTarget
  attr_accessor :name, :goid, :info

  def initialize(name = "Enemy", goid = "slash_enemy_goid_1")
    @name = name
    @goid = goid
    @info = SlashMockInfo.new
  end
end

# Recording player double that captures output messages.
class SlashMockPlayer
  attr_accessor :container, :name, :goid, :last_target, :balance, :info
  attr_reader :messages

  def initialize
    @container   = "slash_room_goid_1"
    @name        = "TestSlasher"
    @goid        = "slash_player_goid_1"
    @messages    = []
    @last_target = nil
    @balance     = true
    @info        = SlashMockInfo.new
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Mock room that records out_event calls and can find targets
class SlashMockRoom
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

Given('a stubbed SlashCommand environment') do
  @slash_player       = SlashMockPlayer.new
  @slash_room         = SlashMockRoom.new
  @slash_weapon       = nil
  @slash_target_name  = nil
  @slash_target_obj   = nil
  @slash_combat_ready = true
  @slash_combat_valid = true
  @slash_future_events = []

  # Build a stub manager
  room_ref   = @slash_room
  player_ref = @slash_player

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

Given('slash combat is not ready') do
  @slash_combat_ready = false
end

Given('slash combat is ready') do
  @slash_combat_ready = true
end

Given('the slash player has no slash weapon') do
  @slash_weapon = nil
end

Given('the slash player has a slash weapon') do
  @slash_weapon = SlashMockWeapon.new("sword", "sword")
end

Given('the slash player has a slash weapon called {string}') do |name|
  @slash_weapon = SlashMockWeapon.new(name, "sword")
end

Given('the slash target is {string}') do |target_name|
  @slash_target_name = target_name
  @slash_target_obj = SlashMockTarget.new(target_name.capitalize, "slash_target_goid_1")
  @slash_room.register(target_name, @slash_target_obj)
end

Given('there is no slash target') do
  @slash_target_name = nil
end

Given('the slash player has no last_target') do
  @slash_player.last_target = nil
end

Given('the slash player last_target is {string}') do |target_name|
  @slash_target_obj = SlashMockTarget.new(target_name.capitalize, "slash_target_goid_1")
  @slash_room.register(target_name, @slash_target_obj)
  @slash_player.last_target = target_name
end

Given('slash combat valid_target returns false') do
  @slash_combat_valid = false
end

Given('slash combat valid_target returns true') do
  @slash_combat_valid = true
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('the SlashCommand action is invoked') do
  # Set up Combat stubs based on scenario state
  combat_ready_val = @slash_combat_ready
  combat_valid_val = @slash_combat_valid
  future_events_ref = @slash_future_events

  ::Combat.define_singleton_method(:ready?) { |_player| combat_ready_val }
  ::Combat.define_singleton_method(:valid_target?) { |_player, _target| combat_valid_val }
  ::Combat.define_singleton_method(:future_event) { |event| future_events_ref << event }

  # Build the command data
  data = {}
  data[:target] = @slash_target_name if @slash_target_name

  @slash_command = Aethyr::Core::Actions::Slash::SlashCommand.new(@slash_player, **data)

  # Stub get_weapon on the command instance
  weapon_ref = @slash_weapon
  @slash_command.define_singleton_method(:get_weapon) { |_player, _type| weapon_ref }

  @slash_command.action
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the slash player should have no output') do
  assert(@slash_player.messages.empty?,
    "Expected no slash player output, got: #{@slash_player.messages.inspect}")
end

Then('the slash player should see {string}') do |fragment|
  match = @slash_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected slash player output containing #{fragment.inspect}, got: #{@slash_player.messages.inspect}")
end

Then('the slash player should not see {string}') do |fragment|
  match = @slash_player.messages.any? { |m| m.include?(fragment) }
  assert(!match,
    "Expected slash player output NOT to contain #{fragment.inspect}, but got: #{@slash_player.messages.inspect}")
end

Then('the slash player last_target should be set to the target goid') do
  assert_equal(@slash_target_obj.goid, @slash_player.last_target,
    "Expected player last_target to be #{@slash_target_obj.goid.inspect}, got: #{@slash_player.last_target.inspect}")
end

Then('the slash command to_other should contain {string}') do |fragment|
  value = @slash_command[:to_other].to_s
  assert(value.include?(fragment),
    "Expected slash command to_other containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the slash command to_target should contain {string}') do |fragment|
  value = @slash_command[:to_target].to_s
  assert(value.include?(fragment),
    "Expected slash command to_target containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the slash command to_player should contain {string}') do |fragment|
  value = @slash_command[:to_player].to_s
  assert(value.include?(fragment),
    "Expected slash command to_player containing #{fragment.inspect}, got: #{value.inspect}")
end

Then('the slash command action should be :weapon_hit') do
  assert_equal(:weapon_hit, @slash_command[:action],
    "Expected slash command action to be :weapon_hit, got: #{@slash_command[:action].inspect}")
end

Then('the slash command combat_action should be :slash') do
  assert_equal(:slash, @slash_command[:combat_action],
    "Expected slash command combat_action to be :slash, got: #{@slash_command[:combat_action].inspect}")
end

Then('the slash command blockable should be true') do
  assert_equal(true, @slash_command[:blockable],
    "Expected slash command blockable to be true, got: #{@slash_command[:blockable].inspect}")
end

Then('the slash player balance should be false') do
  assert_equal(false, @slash_player.balance,
    "Expected slash player balance to be false")
end

Then('the slash player should be in combat') do
  assert_equal(true, @slash_player.info.in_combat,
    "Expected slash player to be in combat")
end

Then('the slash target should be in combat') do
  assert_equal(true, @slash_target_obj.info.in_combat,
    "Expected slash target to be in combat")
end

Then('the slash room should have received out_event') do
  assert(!@slash_room.events.empty?,
    "Expected slash room to receive out_event, but it did not.")
end

Then('slash combat should have received future_event') do
  assert(!@slash_future_events.empty?,
    "Expected Combat.future_event to have been called, but it was not.")
end
