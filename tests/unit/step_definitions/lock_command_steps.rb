# frozen_string_literal: true
###############################################################################
# Step definitions for LockCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/lock'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module LockWorld
  attr_accessor :lock_player, :lock_room, :lock_object, :lock_command,
                :lock_other_side, :lock_other_room
end
World(LockWorld)

###############################################################################
# Ensure Door constant exists at top-level for is_a? check (line 45)         #
###############################################################################
unless defined?(::Door)
  Object.const_set(:Door, Class.new)
end

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Mock inventory that supports include? for key checking (line 30)
class LockMockInventory
  def initialize
    @items = []
  end

  def add(item)
    @items << item
  end

  def include?(item)
    @items.include?(item)
  end
end

# Recording player double that captures output messages.
class LockPlayer
  attr_accessor :container, :name, :goid, :admin
  attr_reader :messages, :inventory

  def initialize
    @container = "room_goid_1"
    @name      = "TestLocker"
    @goid      = "player_goid_1"
    @messages  = []
    @admin     = false
    @inventory = LockMockInventory.new
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def search_inv(_name)
    nil
  end
end

# Mock lockable game object (e.g. a chest)
class LockGameObject
  attr_accessor :name, :locked_state, :lockable_state, :key_list, :can_lock

  def initialize(name, opts = {})
    @name          = name
    @locked_state  = opts.fetch(:locked, false)
    @lockable_state = opts.fetch(:lockable, true)
    @can_lock      = opts.fetch(:can_lock, true)
    @key_list      = opts.fetch(:keys, [])
    @lock_called_with = nil
  end

  def can?(sym)
    sym == :lock ? @can_lock : false
  end

  def lockable?
    @lockable_state
  end

  def locked?
    @locked_state
  end

  def keys
    @key_list
  end

  def lock(key, admin = false)
    if @lockable_state && !@locked_state && (@key_list.include?(key) || admin)
      @locked_state = true
      true
    else
      false
    end
  end
end

# Mock object that always fails to lock
class LockFailObject < LockGameObject
  def lock(_key, _admin = false)
    false
  end
end

# Mock door that supports is_a?(Door) and connected? (lines 45-51)
class LockDoorObject < ::Door
  attr_accessor :name, :locked_state, :lockable_state, :key_list, :can_lock,
                :connected_state, :connected_to, :container

  def initialize(name, opts = {})
    @name            = name
    @locked_state    = opts.fetch(:locked, false)
    @lockable_state  = opts.fetch(:lockable, true)
    @can_lock        = opts.fetch(:can_lock, true)
    @key_list        = opts.fetch(:keys, [])
    @connected_state = false
    @connected_to    = nil
    @container       = nil
  end

  def can?(sym)
    sym == :lock ? @can_lock : false
  end

  def lockable?
    @lockable_state
  end

  def locked?
    @locked_state
  end

  def keys
    @key_list
  end

  def lock(key, admin = false)
    if @lockable_state && !@locked_state && (@key_list.include?(key) || admin)
      @locked_state = true
      true
    else
      false
    end
  end

  def connected?
    @connected_state
  end
end

# Mock room that records events and can find objects
class LockRoom
  attr_reader :events

  def initialize
    @events  = []
    @objects = {}
  end

  def register(name, obj)
    @objects[name] = obj
  end

  def find(_name)
    @objects.values.first
  end

  def out_event(event)
    @events << event
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed LockCommand environment') do
  @lock_player     = LockPlayer.new
  @lock_room       = LockRoom.new
  @lock_object     = nil
  @lock_other_side = nil
  @lock_other_room = nil

  room_ref   = @lock_room
  player_ref = @lock_player
  other_side_ref = -> { @lock_other_side }
  other_room_ref = -> { @lock_other_room }

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref
    else
      nil
    end
  end

  mgr.define_singleton_method(:find) do |id|
    if other_side_ref.call && other_side_ref.call.respond_to?(:connected_to) && id == other_side_ref.call.connected_to
      other_side_ref.call
    elsif other_room_ref.call && other_side_ref.call && id == other_side_ref.call.container
      other_room_ref.call
    else
      nil
    end
  end

  $manager = mgr
end

Given('the lock target object is not found') do
  # Room finds nothing, player search_inv returns nil
  @lock_room = LockRoom.new
  # Rewire manager with the empty room
  room_ref   = @lock_room
  player_ref = @lock_player
  $manager.define_singleton_method(:get_object) do |goid|
    goid == player_ref.container ? room_ref : nil
  end
end

Given('a lock target object {string} that cannot be locked') do |name|
  @lock_object = LockGameObject.new(name, can_lock: false, lockable: false)
  @lock_room.register(name, @lock_object)
end

Given('a lock target object {string} that is already locked') do |name|
  @lock_object = LockGameObject.new(name, locked: true, lockable: true)
  @lock_room.register(name, @lock_object)
end

Given('a lock target object {string} that is lockable and unlocked with key {string}') do |name, key|
  @lock_object = LockGameObject.new(name, locked: false, lockable: true, keys: [key])
  @lock_room.register(name, @lock_object)
end

Given('the lock player does not have the key') do
  # Inventory is empty by default; nothing to do
end

Given('the lock player has key {string} in inventory') do |key|
  @lock_player.inventory.add(key)
end

Given('the lock player is an admin') do
  @lock_player.admin = true
end

Given('a lock target door {string} that is lockable and unlocked with key {string}') do |name, key|
  @lock_object = LockDoorObject.new(name, locked: false, lockable: true, keys: [key])
  @lock_room.register(name, @lock_object)
end

Given('the lock door is connected to another door') do
  @lock_other_side = LockDoorObject.new("other oak door", locked: false, lockable: true, keys: @lock_object.key_list.dup)
  @lock_other_side.container = "other_room_goid"
  @lock_other_room = LockRoom.new

  @lock_object.connected_state = true
  @lock_object.connected_to = "other_door_goid"

  other_side = @lock_other_side
  other_room = @lock_other_room

  $manager.define_singleton_method(:find) do |id|
    if id == "other_door_goid"
      other_side
    elsif id == other_side.container
      other_room
    else
      nil
    end
  end
end

Given('a lock target object {string} that fails to lock') do |name|
  @lock_object = LockFailObject.new(name, locked: false, lockable: true, keys: ["gold_key"])
  @lock_room.register(name, @lock_object)
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the LockCommand action is invoked') do
  object_name = @lock_object ? @lock_object.name : "nonexistent"
  @lock_command = Aethyr::Core::Actions::Lock::LockCommand.new(
    @lock_player, object: object_name
  )
  @lock_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the lock player should see {string}') do |fragment|
  match = @lock_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@lock_player.messages.inspect}")
end

Then('the lock event to_player should be {string}') do |expected|
  value = @lock_command[:to_player]
  assert(value, 'to_player was not set on the lock event')
  assert_equal(expected, value)
end

Then('the lock event to_other should be {string}') do |expected|
  value = @lock_command[:to_other]
  assert(value, 'to_other was not set on the lock event')
  assert_equal(expected, value)
end

Then('the lock event to_blind_other should be {string}') do |expected|
  value = @lock_command[:to_blind_other]
  assert(value, 'to_blind_other was not set on the lock event')
  assert_equal(expected, value)
end

Then('the lock room should have received an event') do
  assert(!@lock_room.events.empty?,
    'Expected room.out_event to have been called but no events recorded')
end

Then('the lock other side should have been locked') do
  assert(@lock_other_side.locked?,
    'Expected the other side door to be locked')
end

Then('the lock other room should have received an event') do
  assert(!@lock_other_room.events.empty?,
    'Expected other room.out_event to have been called but no events recorded')
end
