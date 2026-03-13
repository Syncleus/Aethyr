# frozen_string_literal: true
###############################################################################
# Step definitions for WearCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/wear'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module WearCommandWorld
  attr_accessor :wear_player, :wear_room, :wear_cmd_instance
end
World(WearCommandWorld)

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
class WearMockObject
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
class WearMockWeapon < ::Weapon
  def initialize(name = "weapon")
    super(name)
  end
end

# Mock inventory with configurable find result
class WearMockInventory
  attr_accessor :find_result

  def initialize
    @find_result = nil
  end

  def find(_name)
    @find_result
  end
end

# Recording player double that captures output messages
class WearMockPlayer
  attr_accessor :container, :name, :goid, :inventory
  attr_reader   :messages
  attr_accessor :wear_result

  def initialize
    @container   = "wear_room_goid_1"
    @name        = "WearTester"
    @goid        = "wear_player_goid_1"
    @messages    = []
    @inventory   = WearMockInventory.new
    @wear_result = true
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def wear(_object)
    @wear_result
  end
end

# Mock room that records out_event calls
class WearMockRoom
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
Given('a stubbed WearCommand environment') do
  @wear_player = WearMockPlayer.new
  @wear_room   = WearMockRoom.new
  @wear_cmd_instance = nil

  # Provide log method if not defined
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Stub $manager so get_object returns the mock room
  room_ref   = @wear_room
  player_ref = @wear_player

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

Given('the wear inventory find returns nil for {string}') do |_name|
  @wear_player.inventory.find_result = nil
end

Given('the wear inventory find returns an item called {string}') do |name|
  @wear_player.inventory.find_result = WearMockObject.new(name)
end

Given('the wear inventory find returns a weapon called {string}') do |name|
  @wear_player.inventory.find_result = WearMockWeapon.new(name)
end

Given('the wear player wear will return true') do
  @wear_player.wear_result = true
end

Given('the wear player wear will return false') do
  @wear_player.wear_result = false
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the WearCommand action is invoked with object {string}') do |object_name|
  @wear_cmd_instance = Aethyr::Core::Actions::Wear::WearCommand.new(
    @wear_player,
    object: object_name
  )
  @wear_cmd_instance.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the wear player should see {string}') do |fragment|
  match = @wear_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected wear player output containing #{fragment.inspect}, " \
    "got: #{@wear_player.messages.inspect}")
end

Then('the wear event to_player should contain {string}') do |fragment|
  to_player = @wear_cmd_instance[:to_player].to_s
  assert(to_player.include?(fragment),
    "Expected to_player containing #{fragment.inspect}, got: #{to_player.inspect}")
end

Then('the wear event to_other should contain {string}') do |fragment|
  to_other = @wear_cmd_instance[:to_other].to_s
  assert(to_other.include?(fragment),
    "Expected to_other containing #{fragment.inspect}, got: #{to_other.inspect}")
end

Then('the wear room should receive out_event') do
  assert(!@wear_room.events.empty?,
    "Expected room to receive out_event, but it did not.")
end

Then('the wear room should not receive out_event') do
  assert(@wear_room.events.empty?,
    "Expected room NOT to receive out_event, but it did: #{@wear_room.events.inspect}")
end
