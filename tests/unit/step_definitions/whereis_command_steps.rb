# frozen_string_literal: true
###############################################################################
# Step definitions for WhereisCommand action coverage.                        #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/whereis'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module WhereisWorld
  attr_accessor :whereis_player, :whereis_room, :whereis_command,
                :whereis_target, :whereis_area_map, :whereis_container_map,
                :whereis_recursive_called
end
World(WhereisWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class WhereisMockPlayer
  attr_accessor :container, :name, :goid

  def initialize
    @container = "whereis_room_goid_1"
    @name      = "WhereisTestPlayer"
    @goid      = "whereis_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def messages
    @messages
  end
end

# Mock room
class WhereisMockRoom
  attr_accessor :name

  def initialize
    @name = "WhereisTestRoom"
  end
end

# Mock game object for whereis lookups
class WhereisMockObject
  attr_accessor :container, :name, :area_value, :can_area, :goid

  def initialize(name)
    @name       = name
    @container  = nil
    @area_value = nil
    @can_area   = false
    @goid       = "#{name}_goid"
  end

  def can?(ability)
    ability == :area && @can_area
  end

  def area
    @area_value
  end

  def to_s
    @name
  end
end

# Mock area / container object returned by $manager.get_object
class WhereisMockContainer
  attr_accessor :name, :goid

  def initialize(name, goid = nil)
    @name = name
    @goid = goid || "#{name}_goid"
  end

  def to_s
    @name
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed WhereisCommand environment') do
  @whereis_player = WhereisMockPlayer.new
  @whereis_room   = WhereisMockRoom.new
  @whereis_target = nil
  @whereis_area_map      = {}
  @whereis_container_map = {}
  @whereis_recursive_called = false

  # Provide log method if not already available
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager
  player_ref    = @whereis_player
  room_ref      = @whereis_room
  target_ref    = -> { @whereis_target }
  area_map_ref  = @whereis_area_map
  container_map = @whereis_container_map

  mgr = Object.new

  # get_object resolves room by player.container, plus area/container lookups
  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref
    elsif area_map_ref.key?(goid)
      area_map_ref[goid]
    elsif container_map.key?(goid)
      container_map[goid]
    else
      nil
    end
  end

  # find is called by CommandAction#find_object
  # We return the pre-configured target when name matches
  mgr.define_singleton_method(:find) do |name, _context|
    t = target_ref.call
    if t && t.name == name
      t
    else
      nil
    end
  end

  $manager = mgr
end

Given('the whereis target object is not found') do
  @whereis_target = nil
end

Given('the whereis target object {string} has no container') do |name|
  @whereis_target = WhereisMockObject.new(name)
  @whereis_target.container = nil
end

Given('the whereis target object can area with area id {string}') do |area_id|
  @whereis_target.can_area   = true
  @whereis_target.area_value = area_id
end

Given('the whereis manager resolves area {string} to {string}') do |area_id, area_name|
  @whereis_area_map[area_id] = WhereisMockContainer.new(area_name, area_id)
end

Given('the whereis target object can area but area is nil') do
  @whereis_target.can_area   = true
  @whereis_target.area_value = nil
end

Given('the whereis target object cannot area') do
  @whereis_target.can_area = false
end

Given('the whereis target object can area with area equal to self') do
  @whereis_target.can_area   = true
  @whereis_target.area_value = @whereis_target
end

Given('the whereis target object {string} has container {string}') do |name, container_id|
  @whereis_target = WhereisMockObject.new(name)
  @whereis_target.container = container_id
end

Given('the whereis manager resolves container {string} to {string} with goid {string}') do |container_id, container_name, goid|
  @whereis_container_map[container_id] = WhereisMockContainer.new(container_name, goid)
end

Given('the whereis manager returns nil for container {string}') do |container_id|
  @whereis_container_map[container_id] = nil
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the WhereisCommand action is invoked for {string}') do |object_name|
  @whereis_command = Aethyr::Core::Actions::Whereis::WhereisCommand.new(
    @whereis_player,
    object: object_name
  )
  @whereis_command.action
end

When('the WhereisCommand action is invoked for {string} with whereis stubbed') do |object_name|
  @whereis_command = Aethyr::Core::Actions::Whereis::WhereisCommand.new(
    @whereis_player,
    object: object_name
  )

  # Stub the recursive whereis call so line 38 is reached without error
  recursive_flag = -> { @whereis_recursive_called = true }
  @whereis_command.define_singleton_method(:whereis) do |*_args|
    recursive_flag.call
  end

  @whereis_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the whereis player should see {string}') do |fragment|
  match = @whereis_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected whereis player output containing #{fragment.inspect}, got: #{@whereis_player.messages.inspect}")
end

Then('the whereis recursive call should have been made') do
  assert(@whereis_recursive_called,
    "Expected the recursive whereis call to have been made, but it was not.")
end
