# frozen_string_literal: true
###############################################################################
# Step definitions for RemoveCommand action coverage.                         #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/remove'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module RemoveCommandWorld
  attr_accessor :remove_cmd_player, :remove_cmd_room, :remove_cmd_instance
end
World(RemoveCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Ensure ::Weapon exists for the is_a? check in the source
unless defined?(::Weapon)
  class ::Weapon
    attr_accessor :name
    def initialize(name = "weapon")
      @name = name
    end
  end
end

# A non-weapon item stub
class RemoveMockObject
  attr_accessor :name

  def initialize(name = "item")
    @name = name
  end

  # Explicitly not a Weapon
  def is_a?(klass)
    return false if klass == ::Weapon
    super
  end
end

# A weapon item stub that IS a Weapon
class RemoveMockWeapon < ::Weapon
  def initialize(name = "weapon")
    super(name)
  end
end

# Mock equipment with configurable find result
class RemoveMockEquipment
  attr_accessor :find_result

  def initialize
    @find_result = nil
  end

  def find(_name)
    @find_result
  end
end

# Mock inventory with configurable full? result
class RemoveMockInventory
  attr_accessor :is_full

  def initialize
    @is_full = false
  end

  def full?
    @is_full
  end
end

# Recording player double that captures output messages
class RemoveMockPlayer
  attr_accessor :container, :name, :goid, :inventory, :equipment
  attr_reader   :messages
  attr_accessor :remove_result

  def initialize
    @container     = "remove_room_goid_1"
    @name          = "RemoveTester"
    @goid          = "remove_player_goid_1"
    @messages      = []
    @inventory     = RemoveMockInventory.new
    @equipment     = RemoveMockEquipment.new
    @remove_result = true
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def remove(_object, _position = nil)
    @remove_result
  end
end

# Mock room that records out_event calls
class RemoveMockRoom
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
Given('a stubbed RemoveCommand environment') do
  @remove_cmd_player = RemoveMockPlayer.new
  @remove_cmd_room   = RemoveMockRoom.new
  @remove_cmd_instance = nil

  # Provide log method if not defined
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Stub $manager so get_object returns the mock room
  room_ref   = @remove_cmd_room
  player_ref = @remove_cmd_player

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

Given('the remove equipment find returns nil for {string}') do |_name|
  @remove_cmd_player.equipment.find_result = nil
end

Given('the remove equipment find returns an item called {string}') do |name|
  @remove_cmd_player.equipment.find_result = RemoveMockObject.new(name)
end

Given('the remove equipment find returns a weapon for {string}') do |name|
  @remove_cmd_player.equipment.find_result = RemoveMockWeapon.new(name)
end

Given('the remove player inventory is full') do
  @remove_cmd_player.inventory.is_full = true
end

Given('the remove player inventory is not full') do
  @remove_cmd_player.inventory.is_full = false
end

Given('the remove player remove will return true') do
  @remove_cmd_player.remove_result = true
end

Given('the remove player remove will return false') do
  @remove_cmd_player.remove_result = false
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the RemoveCommand action is invoked with object {string}') do |object_name|
  @remove_cmd_instance = Aethyr::Core::Actions::Remove::RemoveCommand.new(
    @remove_cmd_player,
    object: object_name
  )
  @remove_cmd_instance.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the remove player should see {string}') do |fragment|
  match = @remove_cmd_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected remove player output containing #{fragment.inspect}, " \
    "got: #{@remove_cmd_player.messages.inspect}")
end

Then('the remove event to_player should contain {string}') do |fragment|
  to_player = @remove_cmd_instance[:to_player].to_s
  assert(to_player.include?(fragment),
    "Expected to_player containing #{fragment.inspect}, got: #{to_player.inspect}")
end

Then('the remove event to_other should contain {string}') do |fragment|
  to_other = @remove_cmd_instance[:to_other].to_s
  assert(to_other.include?(fragment),
    "Expected to_other containing #{fragment.inspect}, got: #{to_other.inspect}")
end

Then('the remove room should receive out_event') do
  assert(!@remove_cmd_room.events.empty?,
    "Expected room to receive out_event, but it did not.")
end
