# frozen_string_literal: true
###############################################################################
# Step definitions for DropCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/drop'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module DropWorld
  attr_accessor :drop_player, :drop_room, :drop_item_object, :drop_last_command
end
World(DropWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Mock inventory that supports find, remove, add
class DropMockInventory
  attr_reader :items

  def initialize
    @items = []
    @aliases = {}
  end

  def register_alias(lookup_name, obj)
    @aliases[lookup_name.to_s.downcase] = obj
  end

  def find(name)
    @aliases[name.to_s.downcase] || @items.detect { |i| i.name.downcase == name.to_s.downcase }
  end

  def remove(obj)
    @items.delete(obj)
  end

  def add(obj)
    @items << obj
  end
end

# Mock equipment that supports worn_or_wielded?
class DropMockEquipment
  def initialize
    @responses = {}
  end

  def set_response(item_name, response)
    @responses[item_name.to_s.downcase] = response
  end

  def worn_or_wielded?(item_name)
    @responses[item_name.to_s.downcase]
  end
end

# Recording player double that captures output messages.
class DropPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages, :inventory, :equipment

  def initialize
    @container = "drop_room_goid_1"
    @name      = "TestDropper"
    @goid      = "drop_player_goid_1"
    @messages  = []
    @inventory = DropMockInventory.new
    @equipment = DropMockEquipment.new
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Mock game object (item to drop)
class DropGameObject
  attr_accessor :name, :container

  def initialize(name)
    @name      = name
    @container = nil
  end
end

# Mock room
class DropMockRoom
  attr_accessor :goid
  attr_reader :out_events, :objects

  def initialize(goid = "drop_room_goid_1")
    @goid       = goid
    @out_events = []
    @objects    = []
  end

  def out_event(event)
    @out_events << event
  end

  def add(obj)
    @objects << obj
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed DropCommand environment') do
  @drop_player      = DropPlayer.new
  @drop_room        = DropMockRoom.new("drop_room_goid_1")
  @drop_item_object = nil

  # Provide log method if not already available
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager
  room_ref   = @drop_room
  player_ref = @drop_player

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref
    else
      nil
    end
  end

  $manager = mgr
end

Given('drop item {string} is in player inventory') do |item_name|
  @drop_item_object = DropGameObject.new("shiny #{item_name}")
  @drop_player.inventory.add(@drop_item_object)
  @drop_player.inventory.register_alias(item_name, @drop_item_object)
end

Given('drop item {string} is not in player inventory') do |_item_name|
  # Inventory is empty by default, nothing to do
end

Given('drop equipment reports worn or wielded {string} for {string}') do |response, item_name|
  @drop_player.equipment.set_response(item_name, response)
end

Given('drop equipment does not report worn or wielded for {string}') do |_item_name|
  # Equipment returns nil by default for unknown items, nothing to do
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the DropCommand action is invoked with object {string}') do |object_name|
  @drop_last_command = Aethyr::Core::Actions::Drop::DropCommand.new(
    @drop_player,
    object: object_name
  )
  @drop_last_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the DropCommand should be instantiated successfully') do
  cmd = Aethyr::Core::Actions::Drop::DropCommand.new(@drop_player, object: "test")
  assert_not_nil(cmd, "Expected DropCommand to be instantiated")
end

Then('the drop player should see {string}') do |fragment|
  match = @drop_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected drop player output containing #{fragment.inspect}, got: #{@drop_player.messages.inspect}")
end

Then('the drop player inventory should not have the item') do
  assert(!@drop_player.inventory.items.include?(@drop_item_object),
    "Expected player inventory NOT to contain the item, but it does.")
end

Then('the drop item should be in the room') do
  assert(@drop_room.objects.include?(@drop_item_object),
    "Expected room to contain the dropped item, but it does not.")
  assert_equal(@drop_room.goid, @drop_item_object.container,
    "Expected item container to be room goid.")
end

Then('the drop room should have an out_event') do
  assert(!@drop_room.out_events.empty?,
    "Expected room to have out_events, but none were recorded.")
end

Then('the drop event to_player should contain {string}') do |fragment|
  actual = @drop_last_command[:to_player].to_s
  assert(actual.include?(fragment),
    "Expected to_player containing #{fragment.inspect}, got: #{actual.inspect}")
end

Then('the drop event to_other should contain {string}') do |fragment|
  actual = @drop_last_command[:to_other].to_s
  assert(actual.include?(fragment),
    "Expected to_other containing #{fragment.inspect}, got: #{actual.inspect}")
end

Then('the drop event to_blind_other should be {string}') do |expected|
  actual = @drop_last_command[:to_blind_other].to_s
  assert_equal(expected, actual,
    "Expected to_blind_other to be #{expected.inspect}, got: #{actual.inspect}")
end
