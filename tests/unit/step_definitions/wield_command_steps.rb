# frozen_string_literal: true
###############################################################################
# Step definitions for WieldCommand action coverage.                          #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/wield'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module WieldWorld
  attr_accessor :wield_player, :wield_room, :wield_weapon_name,
                :wield_side, :wield_check_wield_result,
                :wield_wear_result, :wield_weapon_removed,
                :wield_room_event_received
end
World(WieldWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# A mock weapon that IS-A Weapon (via class name check).
# We define a top-level Weapon class if not already present so that
# `weapon.is_a? Weapon` returns true in the production code.
unless defined?(::Weapon)
  class ::Weapon
    attr_accessor :name, :goid, :position, :layer, :container
    def initialize(name = "sword")
      @name = name
      @goid = "weapon_goid_1"
      @position = :wield
      @layer = 0
      @container = nil
    end
  end
end

# A non-weapon item (NOT a Weapon)
class WieldNonWeaponItem
  attr_accessor :name, :goid
  def initialize(name = "rock")
    @name = name
    @goid = "nonweapon_goid_1"
  end
end

# Mock inventory that supports find and remove
class WieldMockInventory
  attr_reader :items, :removed_items

  def initialize
    @items = {}
    @removed_items = []
  end

  def add(name, item)
    @items[name] = item
  end

  def find(name)
    @items[name]
  end

  def remove(item)
    @removed_items << item
    @items.delete_if { |_k, v| v == item }
  end
end

# Mock equipment that supports find, get_all_wielded, check_wield, wear
class WieldMockEquipment
  attr_accessor :find_result, :wielded_items, :check_wield_result, :wear_result

  def initialize
    @find_result = nil
    @wielded_items = []
    @check_wield_result = nil
    @wear_result = :right_wield
  end

  def find(name)
    @find_result
  end

  def get_all_wielded
    @wielded_items
  end

  def check_wield(item, position = nil)
    @check_wield_result
  end

  def wear(item, position = nil)
    @wear_result
  end
end

# Recording player double that captures output messages.
class WieldMockPlayer
  attr_accessor :container, :name, :goid, :inventory, :equipment
  attr_reader :messages

  def initialize
    @container = "room_goid_1"
    @name      = "TestPlayer"
    @goid      = "player_goid_1"
    @messages  = []
    @inventory = WieldMockInventory.new
    @equipment = WieldMockEquipment.new
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Mock room that records out_event calls
class WieldMockRoom
  attr_reader :events

  def initialize
    @events = []
  end

  def out_event(event)
    @events << event
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed WieldCommand environment') do
  @wield_player = WieldMockPlayer.new
  @wield_room = WieldMockRoom.new
  @wield_weapon_name = "sword"
  @wield_side = nil
  @wield_check_wield_result = nil
  @wield_wear_result = :right_wield
  @wield_weapon_removed = false
  @wield_room_event_received = false

  # Provide log method if not defined
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager
  room_ref = @wield_room
  player_ref = @wield_player

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

Given('the player has no weapon in inventory or equipment') do
  # inventory.find returns nil (no items added)
  # equipment.find returns nil (default)
  @wield_player.equipment.find_result = nil
end

Given('the player has the weapon equipped and already wielded') do
  weapon = ::Weapon.new("sword")
  @wield_player.equipment.find_result = weapon
  @wield_player.equipment.wielded_items = [weapon]
end

Given('the player has the weapon equipped but not wielded') do
  weapon = ::Weapon.new("sword")
  @wield_player.equipment.find_result = weapon
  @wield_player.equipment.wielded_items = []
end

Given('the player has a non-weapon item in inventory') do
  item = WieldNonWeaponItem.new("rock")
  @wield_player.inventory.add(@wield_weapon_name, item)
end

Given('the player has a weapon in inventory') do
  weapon = ::Weapon.new("sword")
  @wield_player.inventory.add(@wield_weapon_name, weapon)
end

Given('the wield side is {string}') do |side|
  @wield_side = side
end

Given('check_wield will return {string}') do |msg|
  @wield_player.equipment.check_wield_result = msg
end

Given('check_wield will return nil') do
  @wield_player.equipment.check_wield_result = nil
end

Given('wear will return nil') do
  @wield_player.equipment.wear_result = nil
end

Given('wear will return a position') do
  @wield_player.equipment.wear_result = :right_wield
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the WieldCommand action is invoked') do
  data = { weapon: @wield_weapon_name }
  data[:side] = @wield_side if @wield_side

  @wield_cmd = Aethyr::Core::Actions::Wield::WieldCommand.new(@wield_player, **data)
  @wield_cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the wield player should see {string}') do |fragment|
  match = @wield_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@wield_player.messages.inspect}")
end

Then('the wield event to_player should contain {string}') do |fragment|
  to_player = @wield_cmd[:to_player].to_s
  assert(to_player.include?(fragment),
    "Expected to_player containing #{fragment.inspect}, got: #{to_player.inspect}")
end

Then('the wield event to_other should contain {string}') do |fragment|
  to_other = @wield_cmd[:to_other].to_s
  assert(to_other.include?(fragment),
    "Expected to_other containing #{fragment.inspect}, got: #{to_other.inspect}")
end

Then('the weapon should be removed from inventory') do
  assert(!@wield_player.inventory.removed_items.empty?,
    "Expected weapon to be removed from inventory, but it was not.")
end

Then('the room should receive out_event') do
  assert(!@wield_room.events.empty?,
    "Expected room to receive out_event, but it did not.")
end
