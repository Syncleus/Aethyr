# frozen_string_literal: true
###############################################################################
# Step definitions for PutCommand action coverage.                            #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/put'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module PutCommandWorld
  attr_accessor :put_player, :put_room, :put_item_obj, :put_container_obj,
                :put_item_name, :put_container_name
end
World(PutCommandWorld)

###############################################################################
# Ensure Container constant exists at top-level for is_a? check (line 32)    #
###############################################################################
unless defined?(::Container)
  Object.const_set(:Container, Class.new)
end

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Mock inventory that supports find, remove, <<
class PutMockInventory
  attr_reader :items, :removed_items

  def initialize
    @items = []
    @removed_items = []
  end

  def find(name)
    @items.detect { |i| i.name == name }
  end

  def remove(obj)
    @removed_items << obj
    @items.delete(obj)
  end

  def <<(obj)
    @items << obj
  end
end

# Mock equipment that can report worn_or_wielded?
class PutMockEquipment
  def initialize
    @responses = {}
  end

  def set_response(item_name, response)
    @responses[item_name] = response
  end

  def worn_or_wielded?(item_name)
    @responses[item_name]
  end
end

# Recording player double that captures output messages.
class PutPlayer
  attr_accessor :container, :name, :goid, :inventory, :equipment
  attr_reader :messages

  def initialize
    @container = "put_room_goid_1"
    @name      = "TestPutter"
    @goid      = "put_player_goid_1"
    @messages  = []
    @inventory = PutMockInventory.new
    @equipment = PutMockEquipment.new
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def search_inv(name)
    nil
  end
end

# Mock game object (item to put)
class PutGameObject
  attr_accessor :name, :container

  def initialize(name)
    @name = name
    @container = nil
  end
end

# Mock container that passes `is_a? Container` check
class PutMockContainer < ::Container
  attr_accessor :name, :can_open, :is_closed, :added_items

  def initialize(name)
    @name = name
    @can_open = false
    @is_closed = false
    @added_items = []
  end

  def can?(ability)
    ability == :open && @can_open
  end

  def closed?
    @is_closed
  end

  def add(obj)
    @added_items << obj
  end
end

# Mock non-container object (does NOT inherit from Container)
class PutNonContainer
  attr_accessor :name

  def initialize(name)
    @name = name
  end
end

# Mock room
class PutMockRoom
  attr_reader :out_events

  def initialize
    @out_events = []
  end

  def out_event(event)
    @out_events << event
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed PutCommand environment') do
  @put_player = PutPlayer.new
  @put_room = PutMockRoom.new
  @put_item_obj = nil
  @put_container_obj = nil
  @put_item_name = nil
  @put_container_name = nil

  # Provide log method if not already available
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager
  room_ref = @put_room
  player_ref = @put_player

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref
    else
      nil
    end
  end

  # $manager.find is used to find the container in the room (line 27)
  container_ref = -> { @put_container_obj }
  mgr.define_singleton_method(:find) do |name, context|
    container_ref.call
  end

  $manager = mgr
end

# --- Item steps ---

Given('put item {string} is not in inventory') do |name|
  @put_item_name = name
  # inventory.find will return nil since nothing was added
end

Given('put equipment reports worn or wielded for {string}') do |name|
  @put_player.equipment.set_response(name, "You are wearing that")
end

Given('put equipment reports nothing for {string}') do |_name|
  # equipment.worn_or_wielded? returns nil by default (no response set)
end

Given('put item {string} is in inventory') do |name|
  @put_item_name = name
  @put_item_obj = PutGameObject.new(name)
  @put_player.inventory << @put_item_obj
end

# --- Container steps ---

Given('put container {string} is not found anywhere') do |name|
  @put_container_name = name
  @put_container_obj = nil
end

Given('put container {string} is a non-container object') do |name|
  @put_container_name = name
  @put_container_obj = PutNonContainer.new(name)
end

Given('put container {string} is a closed container') do |name|
  @put_container_name = name
  container = PutMockContainer.new(name)
  container.can_open = true
  container.is_closed = true
  @put_container_obj = container
end

Given('put container {string} is an open container') do |name|
  @put_container_name = name
  container = PutMockContainer.new(name)
  container.can_open = true
  container.is_closed = false
  @put_container_obj = container
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the PutCommand action is invoked') do
  data = { item: @put_item_name, container: @put_container_name }

  cmd = Aethyr::Core::Actions::Put::PutCommand.new(@put_player, **data)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the put player should see {string}') do |fragment|
  match = @put_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected put player output containing #{fragment.inspect}, got: #{@put_player.messages.inspect}")
end

Then('the put item should be removed from player inventory') do
  assert(!@put_player.inventory.removed_items.empty?,
    "Expected item to be removed from player inventory, but nothing was removed.")
end

Then('the put item should be added to the container') do
  assert(@put_container_obj.added_items.include?(@put_item_obj),
    "Expected item to be added to container, but it was not.")
end

Then('the put room should have an out_event with to_player {string}') do |expected|
  assert(!@put_room.out_events.empty?,
    "Expected room to have out_events, but none were recorded.")
  event = @put_room.out_events.last
  assert_equal(expected, event[:to_player],
    "Expected to_player #{expected.inspect}, got: #{event[:to_player].inspect}")
end

Then('the put room should have an out_event with to_other {string}') do |expected|
  assert(!@put_room.out_events.empty?,
    "Expected room to have out_events, but none were recorded.")
  event = @put_room.out_events.last
  assert_equal(expected, event[:to_other],
    "Expected to_other #{expected.inspect}, got: #{event[:to_other].inspect}")
end
