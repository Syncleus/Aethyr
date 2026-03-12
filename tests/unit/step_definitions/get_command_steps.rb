# frozen_string_literal: true
###############################################################################
# Step definitions for GetCommand action coverage.                            #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/get'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module GetWorld
  attr_accessor :get_player, :get_room, :get_object, :get_container,
                :get_from_name, :get_object_name,
                :get_container_find_result, :get_object_in_container,
                :get_room_removed, :get_container_removed,
                :get_inventory_items, :get_inventory_full,
                :get_out_events
end
World(GetWorld)

###############################################################################
# Ensure Container constant exists at top-level for is_a? check (line 44)    #
###############################################################################
unless defined?(::Container)
  Object.const_set(:Container, Class.new)
end

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Mock inventory that supports full?, <<, add, find
class GetMockInventory
  attr_reader :items

  def initialize
    @items = []
    @full = false
  end

  def full?
    @full
  end

  def set_full(val)
    @full = val
  end

  def <<(obj)
    @items << obj
  end

  def add(obj)
    @items << obj
  end

  def find(_name)
    nil
  end
end

# Recording player double that captures output messages.
class GetPlayer
  attr_accessor :container, :name, :goid, :inventory
  attr_reader :messages

  def initialize
    @container = "room_goid_1"
    @name      = "TestPlayer"
    @goid      = "player_goid_1"
    @messages  = []
    @inventory = GetMockInventory.new
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Mock game object (item to pick up)
class GetGameObject
  attr_accessor :name, :movable, :container

  def initialize(name, movable = true)
    @name = name
    @movable = movable
    @container = nil
  end
end

# Mock container that passes `is_a? Container` check
class GetMockContainer < ::Container
  attr_accessor :name, :can_open, :is_closed, :removed_objects

  def initialize(name)
    @name = name
    @can_open = false
    @is_closed = false
    @removed_objects = []
  end

  def can?(ability)
    ability == :open && @can_open
  end

  def closed?
    @is_closed
  end

  def remove(obj)
    @removed_objects << obj
  end
end

# Mock non-container object (does NOT inherit from Container)
class GetNonContainer
  attr_accessor :name

  def initialize(name)
    @name = name
  end
end

# Mock room
class GetMockRoom
  attr_accessor :removed_objects, :out_events

  def initialize
    @removed_objects = []
    @out_events = []
  end

  def remove(obj)
    @removed_objects << obj
  end

  def out_event(event)
    @out_events << event
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed GetCommand environment') do
  @get_player = GetPlayer.new
  @get_room = GetMockRoom.new
  @get_object = nil
  @get_container = nil
  @get_from_name = nil
  @get_object_name = "shiny gem"
  @get_container_find_result = nil
  @get_object_in_container = nil
  @get_room_removed = []
  @get_container_removed = []
  @get_inventory_full = false
  @get_out_events = []

  # Provide log method if not already available
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager
  room_ref = @get_room
  player_ref = @get_player
  # Lambdas to capture mutable state
  object_ref = -> { @get_object }
  container_find_ref = -> { @get_container_find_result }
  object_in_container_ref = -> { @get_object_in_container }

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref
    else
      nil
    end
  end

  mgr.define_singleton_method(:find) do |name, context|
    if context.equal?(room_ref)
      # Looking for object/container in room
      container_result = container_find_ref.call
      if container_result
        container_result
      else
        object_ref.call
      end
    elsif context.is_a?(::Container) || (context.respond_to?(:removed_objects))
      # Looking for object inside a container
      object_in_container_ref.call
    else
      nil
    end
  end

  $manager = mgr
end

Given('get target object is not found') do
  @get_object = nil
  @get_object_name = "unicorn"
end

Given('a get target object {string} that is not movable') do |name|
  @get_object = GetGameObject.new(name, false)
  @get_object_name = name
end

Given('a get target object {string} that is movable') do |name|
  @get_object = GetGameObject.new(name, true)
  @get_object_name = name
end

Given('the get player inventory is full') do
  @get_player.inventory.set_full(true)
end

Given('get from container {string} that is not found') do |name|
  @get_from_name = name
  @get_container_find_result = nil
  @get_object_name = "shiny gem"
end

Given('get from target {string} that is not a container') do |name|
  @get_from_name = name
  non_container = GetNonContainer.new(name)
  @get_container_find_result = non_container
  @get_object_name = "shiny gem"
end

Given('get from container {string} that is closed') do |name|
  @get_from_name = name
  container = GetMockContainer.new(name)
  container.can_open = true
  container.is_closed = true
  @get_container_find_result = container
  @get_container = container
  @get_object_name = "shiny gem"
end

Given('get from container {string} that is open') do |name|
  @get_from_name = name
  container = GetMockContainer.new(name)
  container.can_open = true
  container.is_closed = false
  @get_container_find_result = container
  @get_container = container
  @get_object_name = "shiny gem"
end

Given('get target object in container is not found') do
  @get_object_in_container = nil
end

Given('get target object in container {string} is not movable') do |name|
  @get_object_in_container = GetGameObject.new(name, false)
  @get_object_name = name
end

Given('get target object in container {string} is movable') do |name|
  @get_object_in_container = GetGameObject.new(name, true)
  @get_object_name = name
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the GetCommand action is invoked') do
  data = { object: @get_object_name }

  cmd = Aethyr::Core::Actions::Get::GetCommand.new(@get_player, **data)
  cmd.action
end

When('the GetCommand action is invoked with from') do
  data = { object: @get_object_name, from: @get_from_name }

  cmd = Aethyr::Core::Actions::Get::GetCommand.new(@get_player, **data)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the get player should see {string}') do |fragment|
  match = @get_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@get_player.messages.inspect}")
end

Then('the object should be removed from the room') do
  assert(!@get_room.removed_objects.empty?,
    "Expected object to be removed from room, but nothing was removed.")
end

Then('the object should be in the player inventory') do
  assert(!@get_player.inventory.items.empty?,
    "Expected object to be in player inventory, but inventory is empty.")
end

Then('the room should have an out_event with to_player {string}') do |fragment|
  assert(!@get_room.out_events.empty?,
    "Expected room to have out_events, but none were recorded.")
  event = @get_room.out_events.last
  assert(event[:to_player].include?(fragment),
    "Expected to_player containing #{fragment.inspect}, got: #{event[:to_player].inspect}")
end

Then('the room should have an out_event with to_other containing {string}') do |fragment|
  assert(!@get_room.out_events.empty?,
    "Expected room to have out_events, but none were recorded.")
  event = @get_room.out_events.last
  assert(event[:to_other].include?(fragment),
    "Expected to_other containing #{fragment.inspect}, got: #{event[:to_other].inspect}")
end

Then('the object should be removed from the container') do
  assert(!@get_container.removed_objects.empty?,
    "Expected object to be removed from container, but nothing was removed.")
end

Then('the object should be added to the player inventory') do
  assert(!@get_player.inventory.items.empty?,
    "Expected object to be added to player inventory, but inventory is empty.")
end
