# frozen_string_literal: true
###############################################################################
# Step definitions for GiveCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/give'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module GiveWorld
  attr_accessor :give_player, :give_room, :give_item_object,
                :give_receiver_object, :give_inventory_items,
                :give_equipment_responses, :give_receiver_inventory_items,
                :give_last_command
end
World(GiveWorld)

###############################################################################
# Ensure Player and Mobile constants exist for is_a? checks (line 32)        #
###############################################################################
unless defined?(Aethyr::Core::Objects::Player)
  module Aethyr
    module Core
      module Objects
        class Player; end
      end
    end
  end
end

unless defined?(::Mobile)
  Object.const_set(:Mobile, Class.new)
end

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Mock inventory that supports find, remove, add
class GiveMockInventory
  attr_reader :items

  def initialize
    @items = []
    @aliases = {}
  end

  def register_alias(lookup_name, obj)
    @aliases[lookup_name.to_s.downcase] = obj
  end

  def find(name)
    # First check aliases (keyword lookup), then exact name match
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
class GiveMockEquipment
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
class GivePlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages, :inventory, :equipment

  def initialize
    @container = "give_room_goid_1"
    @name      = "TestGiver"
    @goid      = "give_player_goid_1"
    @messages  = []
    @inventory = GiveMockInventory.new
    @equipment = GiveMockEquipment.new
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Mock game object (item to give)
class GiveGameObject
  attr_accessor :name

  def initialize(name)
    @name = name
  end
end

# Mock receiver that IS a Player (passes is_a? Aethyr::Core::Objects::Player)
class GivePlayerReceiver < Aethyr::Core::Objects::Player
  attr_accessor :name
  attr_reader :inventory

  def initialize(name)
    @name = name
    @inventory = GiveMockInventory.new
  end
end

# Mock receiver that IS a Mobile (passes is_a? Mobile)
class GiveMobileReceiver < ::Mobile
  attr_accessor :name
  attr_reader :inventory

  def initialize(name)
    @name = name
    @inventory = GiveMockInventory.new
  end
end

# Mock inanimate object (neither Player nor Mobile)
class GiveInanimateObject
  attr_accessor :name

  def initialize(name)
    @name = name
  end
end

# Mock room
class GiveMockRoom
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
Given('a stubbed GiveCommand environment') do
  @give_player = GivePlayer.new
  @give_room = GiveMockRoom.new
  @give_item_object = nil
  @give_receiver_object = nil
  @give_equipment_responses = {}

  # Provide log method if not already available
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager
  room_ref = @give_room
  player_ref = @give_player
  receiver_ref = -> { @give_receiver_object }

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
      recv = receiver_ref.call
      if recv && recv.name.downcase == name.to_s.downcase
        recv
      else
        nil
      end
    else
      nil
    end
  end

  $manager = mgr
end

Given('give item {string} is not in player inventory') do |_item_name|
  # Inventory is empty by default, nothing to do
end

Given('give equipment does not report worn or wielded for {string}') do |_item_name|
  # Equipment returns nil by default for unknown items, nothing to do
end

Given('give equipment reports worn or wielded {string} for {string}') do |response, item_name|
  @give_player.equipment.set_response(item_name, response)
end

Given('give item {string} is in player inventory') do |item_name|
  @give_item_object = GiveGameObject.new("shiny #{item_name}")
  @give_player.inventory.add(@give_item_object)
  # Register the lookup name so find(item_name) returns this object
  @give_player.inventory.register_alias(item_name, @give_item_object)
end

Given('give receiver {string} is not in room') do |_receiver_name|
  @give_receiver_object = nil
end

Given('give receiver {string} is an inanimate object in room') do |receiver_name|
  @give_receiver_object = GiveInanimateObject.new(receiver_name.capitalize)
end

Given('give receiver {string} is a Player in room') do |receiver_name|
  @give_receiver_object = GivePlayerReceiver.new(receiver_name.capitalize)
end

Given('give receiver {string} is a Mobile in room') do |receiver_name|
  @give_receiver_object = GiveMobileReceiver.new(receiver_name.capitalize)
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the GiveCommand action is invoked with item {string} to {string}') do |item_name, to_name|
  @give_last_command = Aethyr::Core::Actions::Give::GiveCommand.new(
    @give_player,
    item: item_name,
    to: to_name,
    player: @give_player
  )
  @give_last_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the give player should see {string}') do |fragment|
  match = @give_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected give player output containing #{fragment.inspect}, got: #{@give_player.messages.inspect}")
end

Then('the give receiver should have the item') do
  assert(!@give_receiver_object.inventory.items.empty?,
    "Expected receiver inventory to contain the item, but it is empty.")
  assert(@give_receiver_object.inventory.items.include?(@give_item_object),
    "Expected receiver inventory to contain the given item.")
end

Then('the give player inventory should not have the item') do
  assert(!@give_player.inventory.items.include?(@give_item_object),
    "Expected player inventory NOT to contain the item, but it does.")
end

Then('the give room should have an out_event') do
  assert(!@give_room.out_events.empty?,
    "Expected room to have out_events, but none were recorded.")
end

Then('the give event to_player should contain {string}') do |fragment|
  event = @give_last_command
  actual = event[:to_player].to_s
  assert(actual.include?(fragment),
    "Expected to_player containing #{fragment.inspect}, got: #{actual.inspect}")
end

Then('the give event to_target should contain {string}') do |fragment|
  event = @give_last_command
  actual = event[:to_target].to_s
  assert(actual.include?(fragment),
    "Expected to_target containing #{fragment.inspect}, got: #{actual.inspect}")
end

Then('the give event to_other should contain {string}') do |fragment|
  event = @give_last_command
  actual = event[:to_other].to_s
  assert(actual.include?(fragment),
    "Expected to_other containing #{fragment.inspect}, got: #{actual.inspect}")
end
