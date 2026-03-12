# frozen_string_literal: true
###############################################################################
# Step definitions for UnlockCommand action coverage.                         #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/unlock'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module UnlockWorld
  attr_accessor :unlock_player, :unlock_room, :unlock_object,
                :unlock_object_name, :unlock_other_side, :unlock_other_room,
                :unlock_out_events, :unlock_other_room_events
end
World(UnlockWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Mock inventory that supports include? for key checking.
class UnlockMockInventory
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
class UnlockPlayer
  attr_accessor :container, :name, :goid, :admin, :inventory
  attr_reader :messages

  def initialize
    @container = "room_goid_1"
    @name      = "TestPlayer"
    @goid      = "player_goid_1"
    @messages  = []
    @admin     = false
    @inventory = UnlockMockInventory.new
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def search_inv(_name)
    nil
  end
end

# Mock lockable object that supports unlock-related queries.
class UnlockMockObject
  attr_accessor :name, :keys, :lock_state, :can_unlock, :is_lockable,
                :unlock_result

  def initialize(name, opts = {})
    @name          = name
    @can_unlock    = opts.fetch(:can_unlock, true)
    @is_lockable   = opts.fetch(:lockable, true)
    @lock_state    = opts.fetch(:locked, true)
    @keys          = opts.fetch(:keys, [])
    @unlock_result = opts.fetch(:unlock_result, true)
  end

  def can?(ability)
    ability == :unlock && @can_unlock
  end

  def lockable?
    @is_lockable
  end

  def locked?
    @lock_state
  end

  def unlock(_key, _admin = false)
    @unlock_result
  end
end

# Mock door object that also behaves as a Door for is_a? checks.
# We define a top-level Door constant if not already present.
unless defined?(::Door)
  Object.const_set(:Door, Class.new)
end

class UnlockMockDoor < ::Door
  attr_accessor :name, :keys, :lock_state, :can_unlock, :is_lockable,
                :unlock_result, :connected, :connected_to, :container

  def initialize(name, opts = {})
    @name          = name
    @can_unlock    = opts.fetch(:can_unlock, true)
    @is_lockable   = opts.fetch(:lockable, true)
    @lock_state    = opts.fetch(:locked, true)
    @keys          = opts.fetch(:keys, [])
    @unlock_result = opts.fetch(:unlock_result, true)
    @connected     = opts.fetch(:connected, false)
    @connected_to  = opts.fetch(:connected_to, nil)
    @container     = opts.fetch(:container, nil)
    @unlock_called = false
  end

  def can?(ability)
    ability == :unlock && @can_unlock
  end

  def lockable?
    @is_lockable
  end

  def locked?
    @lock_state
  end

  def unlock(_key, _admin = false)
    @unlock_called = true
    @unlock_result
  end

  def unlock_called?
    @unlock_called
  end

  def connected?
    @connected
  end
end

# Mock room that records out_event calls.
class UnlockMockRoom
  attr_reader :out_events

  def initialize
    @out_events = []
  end

  def find(_name)
    nil
  end

  def out_event(event)
    @out_events << event
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed UnlockCommand environment') do
  @unlock_player           = UnlockPlayer.new
  @unlock_room             = UnlockMockRoom.new
  @unlock_object           = nil
  @unlock_object_name      = "thing"
  @unlock_other_side       = nil
  @unlock_other_room       = nil
  @unlock_other_room_events = []

  # Provide log method if not already available
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager
  room_ref   = @unlock_room
  player_ref = @unlock_player
  object_ref = -> { @unlock_object }
  other_side_ref = -> { @unlock_other_side }
  other_room_ref = -> { @unlock_other_room }

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref
    else
      nil
    end
  end

  mgr.define_singleton_method(:find) do |id, *_args|
    os = other_side_ref.call
    if os && os.respond_to?(:connected_to) && id == os.connected_to
      # This shouldn't be hit normally; connected_to is on the main object
    end
    # Check if asking for the other_side by its connected_to id
    obj = object_ref.call
    if obj && obj.respond_to?(:connected_to) && id == obj.connected_to
      other_side_ref.call
    elsif os && os.respond_to?(:container) && id == os.container
      other_room_ref.call
    else
      nil
    end
  end

  $manager = mgr
end

Given('the unlock object is not found') do
  @unlock_object = nil
  @unlock_object_name = "unicorn"

  # Make room.find return nil
  @unlock_room.define_singleton_method(:find) { |_name| nil }

  # Also ensure search_inv returns nil
  @unlock_player.define_singleton_method(:search_inv) { |_name| nil }
end

Given('an unlock target object {string} that cannot be unlocked') do |name|
  @unlock_object = UnlockMockObject.new(name, can_unlock: false, lockable: false, locked: false)
  @unlock_object_name = name

  obj = @unlock_object
  @unlock_room.define_singleton_method(:find) { |_name| obj }
end

Given('an unlock target object {string} that is already unlocked') do |name|
  @unlock_object = UnlockMockObject.new(name, can_unlock: true, lockable: true, locked: false)
  @unlock_object_name = name

  obj = @unlock_object
  @unlock_room.define_singleton_method(:find) { |_name| obj }
end

Given('an unlock target object {string} that is locked with key {string}') do |name, key|
  @unlock_object = UnlockMockObject.new(name,
    can_unlock: true, lockable: true, locked: true,
    keys: [key], unlock_result: true
  )
  @unlock_object_name = name

  obj = @unlock_object
  @unlock_room.define_singleton_method(:find) { |_name| obj }
end

Given('an unlock target object {string} that is locked with key {string} but unlock fails') do |name, key|
  @unlock_object = UnlockMockObject.new(name,
    can_unlock: true, lockable: true, locked: true,
    keys: [key], unlock_result: false
  )
  @unlock_object_name = name

  obj = @unlock_object
  @unlock_room.define_singleton_method(:find) { |_name| obj }
end

Given('the unlock player does not have the key') do
  # inventory has nothing - default state
  @unlock_player.admin = false
end

Given('the unlock player has the key {string}') do |key|
  @unlock_player.inventory.add(key)
  @unlock_player.admin = false
end

Given('the unlock player is an admin') do
  @unlock_player.admin = true
end

Given('an unlock target door {string} that is locked with key {string} and connected') do |name, key|
  @unlock_other_room = UnlockMockRoom.new

  @unlock_other_side = UnlockMockDoor.new("other #{name}",
    can_unlock: true, lockable: true, locked: true,
    keys: [key], unlock_result: true,
    connected: false, connected_to: nil,
    container: "other_room_goid"
  )

  @unlock_object = UnlockMockDoor.new(name,
    can_unlock: true, lockable: true, locked: true,
    keys: [key], unlock_result: true,
    connected: true, connected_to: "other_door_goid"
  )
  @unlock_object_name = name

  obj = @unlock_object
  @unlock_room.define_singleton_method(:find) { |_name| obj }

  # Re-wire the manager to resolve connected door and its room
  room_ref       = @unlock_room
  player_ref     = @unlock_player
  other_side_ref = @unlock_other_side
  other_room_ref = @unlock_other_room

  mgr = $manager

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref
    else
      nil
    end
  end

  mgr.define_singleton_method(:find) do |id, *_args|
    if id == "other_door_goid"
      other_side_ref
    elsif id == "other_room_goid"
      other_room_ref
    else
      nil
    end
  end
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the UnlockCommand action is invoked') do
  data = { object: @unlock_object_name }
  cmd = Aethyr::Core::Actions::Unlock::UnlockCommand.new(@unlock_player, **data)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the unlock player should see {string}') do |fragment|
  match = @unlock_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@unlock_player.messages.inspect}")
end

Then('the unlock room should have an out_event') do
  assert(!@unlock_room.out_events.empty?,
    "Expected room to have out_events, but none were recorded.")
end

Then('the unlock room should have an out_event with to_player {string}') do |fragment|
  assert(!@unlock_room.out_events.empty?,
    "Expected room to have out_events, but none were recorded.")
  event = @unlock_room.out_events.last
  assert(event[:to_player].include?(fragment),
    "Expected to_player containing #{fragment.inspect}, got: #{event[:to_player].inspect}")
end

Then('the unlock room should have an out_event with to_other {string}') do |fragment|
  assert(!@unlock_room.out_events.empty?,
    "Expected room to have out_events, but none were recorded.")
  event = @unlock_room.out_events.last
  assert(event[:to_other].include?(fragment),
    "Expected to_other containing #{fragment.inspect}, got: #{event[:to_other].inspect}")
end

Then('the unlock other side should have been unlocked') do
  assert(@unlock_other_side.unlock_called?,
    "Expected the other side of the door to have unlock called.")
end

Then('the unlock other room should have an out_event') do
  assert(!@unlock_other_room.out_events.empty?,
    "Expected other room to have out_events, but none were recorded.")
end
