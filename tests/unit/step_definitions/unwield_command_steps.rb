# frozen_string_literal: true
###############################################################################
# Step definitions for UnwieldCommand action coverage.                        #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/unwield'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module UnwieldWorld
  attr_accessor :unwield_player, :unwield_room, :unwield_weapon_param,
                :unwield_weapon_set, :unwield_cmd
end
World(UnwieldWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# A simple weapon-like object
class UnwieldWeaponDouble
  attr_accessor :name, :goid
  def initialize(name = "sword")
    @name = name
    @goid = "unwield_weapon_#{name}"
  end
end

# Mock equipment supporting get_wielded, find, position_of, remove
class UnwieldMockEquipment
  attr_accessor :get_wielded_result, :get_wielded_hand_results,
                :find_result, :position_of_result, :remove_result

  def initialize
    @get_wielded_result = nil
    @get_wielded_hand_results = {}
    @find_result = nil
    @position_of_result = :right_wield
    @remove_result = true
  end

  def get_wielded(hand = nil)
    if hand
      @get_wielded_hand_results[hand]
    else
      @get_wielded_result
    end
  end

  def find(name)
    @find_result
  end

  def position_of(weapon)
    @position_of_result
  end

  def remove(weapon)
    @remove_result
  end
end

# Mock inventory that supports <<
class UnwieldMockInventory
  attr_reader :items

  def initialize
    @items = []
  end

  def <<(item)
    @items << item
  end
end

# Recording player double that captures output messages.
class UnwieldMockPlayer
  attr_accessor :container, :name, :goid, :inventory, :equipment
  attr_reader :messages

  def initialize
    @container = "unwield_room_goid_1"
    @name      = "UnwieldTester"
    @goid      = "unwield_player_goid_1"
    @messages  = []
    @inventory = UnwieldMockInventory.new
    @equipment = UnwieldMockEquipment.new
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Mock room that records out_event calls
class UnwieldMockRoom
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
Given('a stubbed UnwieldCommand environment') do
  @unwield_player = UnwieldMockPlayer.new
  @unwield_room   = UnwieldMockRoom.new
  @unwield_weapon_param = nil
  @unwield_weapon_set = false
  @unwield_cmd = nil

  # Provide log method if not defined
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub $manager
  room_ref   = @unwield_room
  player_ref = @unwield_player

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

Given('the unwield weapon is {string}') do |weapon|
  @unwield_weapon_param = weapon
  @unwield_weapon_set = true
end

Given('the unwield weapon is not set') do
  @unwield_weapon_param = nil
  @unwield_weapon_set = false
end

Given('get_wielded for that hand returns nil') do
  # hand results default to nil, nothing to do
end

Given('get_wielded for that hand returns a weapon called {string}') do |name|
  weapon = UnwieldWeaponDouble.new(name)
  hand = @unwield_weapon_param  # "right" or "left"
  @unwield_player.equipment.get_wielded_hand_results[hand] = weapon
end

Given('get_wielded returns nil') do
  @unwield_player.equipment.get_wielded_result = nil
end

Given('get_wielded returns a weapon called {string}') do |name|
  weapon = UnwieldWeaponDouble.new(name)
  @unwield_player.equipment.get_wielded_result = weapon
end

Given('equipment find returns nil') do
  @unwield_player.equipment.find_result = nil
end

Given('equipment find returns a weapon called {string}') do |name|
  weapon = UnwieldWeaponDouble.new(name)
  @unwield_player.equipment.find_result = weapon
end

Given('equipment position_of returns a non-wield position') do
  @unwield_player.equipment.position_of_result = :torso
end

Given('equipment position_of returns a wield position') do
  @unwield_player.equipment.position_of_result = :right_wield
end

Given('equipment remove will succeed') do
  @unwield_player.equipment.remove_result = true
end

Given('equipment remove will fail') do
  @unwield_player.equipment.remove_result = false
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the UnwieldCommand action is invoked') do
  data = {}
  if @unwield_weapon_set
    data[:weapon] = @unwield_weapon_param
  end

  @unwield_cmd = Aethyr::Core::Actions::Unwield::UnwieldCommand.new(
    @unwield_player, **data
  )
  @unwield_cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the unwield player should see {string}') do |fragment|
  match = @unwield_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected unwield player output containing #{fragment.inspect}, " \
    "got: #{@unwield_player.messages.inspect}")
end

Then('the unwield event to_player should contain {string}') do |fragment|
  to_player = @unwield_cmd[:to_player].to_s
  assert(to_player.include?(fragment),
    "Expected to_player containing #{fragment.inspect}, got: #{to_player.inspect}")
end

Then('the unwield event to_other should contain {string}') do |fragment|
  to_other = @unwield_cmd[:to_other].to_s
  assert(to_other.include?(fragment),
    "Expected to_other containing #{fragment.inspect}, got: #{to_other.inspect}")
end

Then('the unwield room should receive out_event') do
  assert(!@unwield_room.events.empty?,
    "Expected room to receive out_event, but it did not.")
end

Then('the weapon should be in the unwield player inventory') do
  assert(!@unwield_player.inventory.items.empty?,
    "Expected weapon to be added to inventory, but inventory is empty.")
end
