# frozen_string_literal: true

###############################################################################
# Step definitions for the Location trait feature.                             #
# Exercises: area, parent_area, flags, and terrain_type methods.               #
#                                                                              #
# Uses lightweight stub objects that include Location directly rather than      #
# constructing real Area/Room objects (avoids complex constructor chains).      #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'

World(Test::Unit::Assertions)

###############################################################################
# Stub manager that can return specific objects by ID.                         #
###############################################################################
unless defined?(LocationTraitStubManager)
  class LocationTraitStubManager
    def initialize
      @objects = {}
    end

    def register(id, obj)
      @objects[id] = obj
    end

    def find(id)
      @objects[id]
    end

    def existing_goid?(_goid); false; end
    def submit_action(_action); end
  end
end

###############################################################################
# Require just the Location module and supporting types.                       #
###############################################################################
require 'aethyr/core/objects/info/info'
require 'aethyr/core/objects/info/terrain'

# Ensure log is available.
unless Object.private_method_defined?(:log)
  Object.class_eval do
    private
    def log(_msg, *_args); end
  end
end

###############################################################################
# Stub flag that tracks negate_flags calls.                                    #
###############################################################################
class LocationTraitTrackingFlag
  attr_reader :id, :affect_desc, :name, :negated_calls

  def initialize(id, name, flags_to_negate = nil)
    @id = id
    @name = name
    @affect_desc = "#{name} effect"
    @flags_to_negate = flags_to_negate
    @negated_calls = 0
  end

  def can_see?(_player); true; end

  def negate_flags(other_flags)
    @negated_calls += 1
    return other_flags if @flags_to_negate.nil? || @flags_to_negate.empty?
    @flags_to_negate.each { |f| other_flags.delete(f) }
  end
end

###############################################################################
# Lightweight stub objects that include Location.                              #
# We require the real module to get real coverage.                             #
###############################################################################
require 'aethyr/core/objects/traits/location'

# Need the Area class to be loadable for is_a? checks.
# Define a minimal module path so Location's is_a? check works.
module Aethyr; module Core; module Objects; end; end; end unless defined?(Aethyr::Core::Objects)

# Stub "Area-like" object that IS an Aethyr::Core::Objects::Area for is_a? purposes
class LocTestArea
  include Location

  attr_accessor :container, :game_object_id, :info

  def initialize(goid)
    @game_object_id = goid
    @container = nil
    @info = Info.new
    @info.flags = {}
  end

  # Make is_a?(Aethyr::Core::Objects::Area) return true
  def is_a?(klass)
    return true if defined?(Aethyr::Core::Objects::Area) && klass == Aethyr::Core::Objects::Area
    super
  end
end

# Stub "Room-like" object that includes Location but is NOT an Area
class LocTestRoom
  include Location

  attr_accessor :container, :game_object_id, :info

  def initialize(goid)
    @game_object_id = goid
    @container = nil
    @info = Info.new
    @info.flags = {}
  end
end

# Stub non-Area container (no Location, not an Area)
class LocTestNonAreaContainer
  attr_accessor :container, :game_object_id

  def initialize(goid, container_id = nil)
    @game_object_id = goid
    @container = container_id
  end

  def is_a?(klass)
    return false if defined?(Aethyr::Core::Objects::Area) && klass == Aethyr::Core::Objects::Area
    super
  end
end

###############################################################################
# World module                                                                 #
###############################################################################
module LocationTraitWorld
  attr_accessor :loc_manager, :loc_area, :loc_room
end
World(LocationTraitWorld)

###############################################################################
# Given steps                                                                  #
###############################################################################
Given('a stubbed Location trait test environment') do
  self.loc_manager = LocationTraitStubManager.new
  $manager = self.loc_manager
end

###############################################################################
# When steps                                                                   #
###############################################################################

# --- area on Area (line 20) ---
When('I create a Location-test Area') do
  self.loc_area = LocTestArea.new("loc_area_#{rand(99999)}")
end

# --- area on Room delegates to parent_area (line 21) ---
When('I create a Location-test Room inside an Area') do
  self.loc_area = LocTestArea.new("loc_area_#{rand(99999)}")
  self.loc_room = LocTestRoom.new("loc_room_#{rand(99999)}")
  self.loc_room.container = self.loc_area.game_object_id
  self.loc_manager.register(self.loc_area.game_object_id, self.loc_area)
end

# --- parent_area traverses intermediate container (line 30) ---
When('I create a Location-test Room nested inside a non-Area container inside an Area') do
  self.loc_area = LocTestArea.new("loc_area_#{rand(99999)}")
  intermediate = LocTestNonAreaContainer.new("loc_mid_#{rand(99999)}", self.loc_area.game_object_id)
  self.loc_room = LocTestRoom.new("loc_room_#{rand(99999)}")
  self.loc_room.container = intermediate.game_object_id
  self.loc_manager.register(intermediate.game_object_id, intermediate)
  self.loc_manager.register(self.loc_area.game_object_id, self.loc_area)
end

# --- parent_area returns nil (line 32) ---
When('I create a Location-test Room inside a non-Area container with no Area above') do
  non_area = LocTestNonAreaContainer.new("loc_top_#{rand(99999)}", nil)
  self.loc_room = LocTestRoom.new("loc_room_#{rand(99999)}")
  self.loc_room.container = non_area.game_object_id
  self.loc_manager.register(non_area.game_object_id, non_area)
end

# --- flags with parent area flags (lines 39-40, 42) ---
When('I create a Location-test Room with local flags inside an Area with flags') do
  self.loc_area = LocTestArea.new("loc_area_#{rand(99999)}")
  area_flag = LocationTraitTrackingFlag.new(:area_buff, "area_buff")
  self.loc_area.info.flags = { area_buff: area_flag }

  self.loc_room = LocTestRoom.new("loc_room_#{rand(99999)}")
  room_flag = LocationTraitTrackingFlag.new(:room_debuff, "room_debuff", [:area_buff])
  self.loc_room.info.flags = { room_debuff: room_flag }

  self.loc_room.container = self.loc_area.game_object_id
  self.loc_manager.register(self.loc_area.game_object_id, self.loc_area)
end

# --- terrain_type with nil local, parent has type (line 47) ---
When('I create a Location-test Room with nil terrain type inside an Area with terrain type') do
  self.loc_area = LocTestArea.new("loc_area_#{rand(99999)}")
  self.loc_area.info.terrain ||= Info.new
  self.loc_area.info.terrain.type = Terrain::CITY

  self.loc_room = LocTestRoom.new("loc_room_#{rand(99999)}")
  self.loc_room.info.terrain ||= Info.new
  self.loc_room.info.terrain.type = nil

  self.loc_room.container = self.loc_area.game_object_id
  self.loc_manager.register(self.loc_area.game_object_id, self.loc_area)
end

# --- terrain_type with nil local and no parent area (line 48) ---
When('I create a Location-test Room with nil terrain type and no parent area') do
  self.loc_room = LocTestRoom.new("loc_room_#{rand(99999)}")
  self.loc_room.info.terrain ||= Info.new
  self.loc_room.info.terrain.type = nil
  self.loc_room.container = nil
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the area method should return itself') do
  result = self.loc_area.area
  assert_equal self.loc_area, result,
    "Expected area() to return self for an Area-like object"
end

Then('the area method on the room should return the parent area') do
  result = self.loc_room.area
  assert_equal self.loc_area, result,
    "Expected area() on Room to return parent Area"
end

Then('parent_area should return the grandparent Area') do
  result = self.loc_room.parent_area
  assert_equal self.loc_area, result,
    "Expected parent_area to traverse through non-Area container and find the Area"
end

Then('parent_area should return nil') do
  result = self.loc_room.parent_area
  assert_nil result,
    "Expected parent_area to return nil when no Area is in the chain"
end

Then('the room flags should include both parent and local flags') do
  result = self.loc_room.flags
  assert result.key?(:room_debuff),
    "Expected merged flags to include the room's local :room_debuff flag"
  assert result.is_a?(Hash), "Expected flags to return a Hash"
end

Then('local flag negation should have been applied') do
  room_flag = self.loc_room.info.flags[:room_debuff]
  assert room_flag.negated_calls > 0,
    "Expected negate_flags to have been called on the room's local flag"
end

Then('the room terrain_type should return the parent area terrain type') do
  result = self.loc_room.terrain_type
  assert_equal Terrain::CITY, result,
    "Expected terrain_type to delegate to parent area's terrain type"
end

Then('the room terrain_type should return nil') do
  result = self.loc_room.terrain_type
  assert_nil result,
    "Expected terrain_type to return nil when local is nil and no parent area"
end
