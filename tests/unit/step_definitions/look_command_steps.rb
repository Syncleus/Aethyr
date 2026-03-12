# frozen_string_literal: true
###############################################################################
# Step definitions for LookCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/look'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module LookCommandWorld
  attr_accessor :look_player, :look_room, :look_command, :look_error,
                :look_target_object, :look_in_target, :look_in_received
end
World(LookCommandWorld)

###############################################################################
# Ensure top-level constants Exit, Room, Area exist for is_a? checks          #
###############################################################################
unless defined?(::Exit)
  Object.const_set(:Exit, Class.new)
end
unless defined?(::Room)
  Object.const_set(:Room, Class.new)
end
unless defined?(::Area)
  Object.const_set(:Area, Class.new)
end

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Mock terrain info for room
class LookMockTerrainInfo
  attr_accessor :indoors, :underwater, :water, :room_type
  def initialize
    @indoors = false
    @underwater = false
    @water = false
    @room_type = nil
  end
end

# Mock info wrapper
class LookMockInfo
  attr_accessor :terrain
  def initialize
    @terrain = LookMockTerrainInfo.new
  end
end

# Mock terrain type (like Terrain::Terrain)
class LookMockTerrainType
  attr_reader :room_text, :area_text
  def initialize(room_text = "part of the grasslands", area_text = "waving grasslands")
    @room_text = room_text
    @area_text = area_text
  end
end

# Mock area (inherits from top-level Area so is_a? Area works)
class LookMockArea < ::Area
  attr_accessor :name, :tt
  def initialize(name = "Test Area")
    @name = name
    @tt = nil
  end

  def terrain_type
    @tt
  end
end

# Mock room (inherits from top-level Room so is_a? Room works)
class LookMockRoom < ::Room
  attr_accessor :name, :room_area, :look_text, :room_tt, :info_obj
  attr_reader :found_objects, :inv_found_objects

  def initialize(name = "TestRoom")
    @name = name
    @room_area = nil
    @look_text = "A nice room"
    @found_objects = {}
    @inv_found_objects = {}
    @info_obj = LookMockInfo.new
    @room_tt = nil
  end

  def info
    @info_obj
  end

  def area
    @room_area
  end

  def look(_player)
    @look_text
  end

  def find(search_name)
    @found_objects[search_name]
  end

  def terrain_type
    @room_tt
  end
end

# Mock exit (inherits from top-level Exit so is_a? Exit works)
class LookMockExit < ::Exit
  attr_reader :peer_text
  def initialize(peer_text)
    @peer_text = peer_text
  end

  def peer
    @peer_text
  end
end

# Mock generic game object
class LookMockGameObject
  attr_accessor :name, :long_desc_text
  def initialize(name, long_desc = "A generic object.")
    @name = name
    @long_desc_text = long_desc
  end

  def long_desc
    @long_desc_text
  end
end

# Mock inventory
class LookMockInventory
  def initialize
    @objects = {}
  end

  def register(name, obj)
    @objects[name] = obj
  end

  def find(name)
    @objects[name]
  end
end

# Mock object that supports look_inside
class LookInsideTarget
  attr_reader :looked_inside
  attr_accessor :can_look_inside

  def initialize(can_look = true)
    @can_look_inside = can_look
    @looked_inside = false
  end

  def can?(ability)
    ability == :look_inside && @can_look_inside
  end

  def look_inside(_event)
    @looked_inside = true
  end
end

# Recording player double that captures output messages.
class LookTestPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "room_goid_1"
    @name      = "LookTestPlayer"
    @goid      = "player_goid_1"
    @messages  = []
    @long_desc = "A brave adventurer."
    @broadcast_callback = nil
    @inv_results = {}
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def broadcast_from(event, *args)
    @broadcast_callback.call(event, *args) if @broadcast_callback
  end

  def set_broadcast_callback(&block)
    @broadcast_callback = block
  end

  def search_inv(name)
    @inv_results[name]
  end

  def register_inv(name, obj)
    @inv_results[name] = obj
  end

  def show_inventory
    "inventory contents"
  end

  def inventory
    @inventory ||= LookMockInventory.new
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed LookCommand environment') do
  @look_player = LookTestPlayer.new
  @look_room = LookMockRoom.new
  @look_target_object = nil
  @look_in_target = nil
  @look_in_received = false
  @look_error = nil

  # Provide log method if not already available
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager
  room_ref = @look_room
  player_ref = @look_player
  room_nil = false

  mgr = Object.new
  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref.instance_variable_get(:@return_nil) ? nil : room_ref
    else
      nil
    end
  end

  $manager = mgr

  # Store for later mutation
  @look_mgr = mgr
end

Given('the look room is nil') do
  @look_room.instance_variable_set(:@return_nil, true)
end

Given('the player is blind with no reason') do
  @look_player.set_broadcast_callback do |_event, *args|
    data = args.first
    data[:can_look] = false
    data[:reason] = nil
  end
end

Given('the player is blind with reason {string}') do |reason|
  @look_player.set_broadcast_callback do |_event, *args|
    data = args.first
    data[:can_look] = false
    data[:reason] = reason
  end
end

Given('a look target exit with peer text {string}') do |peer_text|
  exit_obj = LookMockExit.new(peer_text)
  @look_room.found_objects["north"] = exit_obj
  @look_player.register_inv("north", nil)
end

Given('the look room is indoors') do
  @look_room.info.terrain.indoors = true
end

Given('the look room is underwater') do
  @look_room.info.terrain.underwater = true
end

Given('the look room is water') do
  @look_room.info.terrain.water = true
end

Given('the look room has an area {string} with terrain type') do |area_name|
  area = LookMockArea.new(area_name)
  area.tt = LookMockTerrainType.new
  @look_room.room_area = area
  @look_room.room_tt = LookMockTerrainType.new
end

Given('the look room has no area but has room_type') do
  @look_room.room_area = nil
  @look_room.info.terrain.room_type = :forest
  @look_room.room_tt = LookMockTerrainType.new("a forest clearing")
end

Given('the look room has no area and no room_type') do
  @look_room.room_area = nil
  @look_room.info.terrain.room_type = nil
end

Given('a look target object {string} with long desc {string}') do |name, desc|
  obj = LookMockGameObject.new(name, desc)
  @look_room.found_objects[name] = obj
end

Given('a look in target {string} that cannot be looked inside') do |name|
  @look_in_target = LookInsideTarget.new(false)
  @look_room.found_objects[name] = @look_in_target
end

Given('a look in target {string} that can be looked inside') do |name|
  @look_in_target = LookInsideTarget.new(true)
  @look_room.found_objects[name] = @look_in_target
end

Given('the look room has a terrain type with room_text {string}') do |room_text|
  @look_room.room_tt = LookMockTerrainType.new(room_text)
end

Given('the look room has nil terrain type') do
  @look_room.room_tt = nil
end

Given('the look room has an area {string} with area terrain type {string}') do |area_name, area_text|
  area = LookMockArea.new(area_name)
  area.tt = LookMockTerrainType.new("part of grasslands", area_text)
  @look_room.room_area = area
  @look_room.room_tt = LookMockTerrainType.new
end

Given('the look room has an area {string} with nil area terrain type') do |area_name|
  area = LookMockArea.new(area_name)
  area.tt = nil
  @look_room.room_area = area
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the LookCommand action is invoked with no arguments') do
  cmd = Aethyr::Core::Actions::Look::LookCommand.new(@look_player)
  cmd.action
  @look_command = cmd
end

When('the LookCommand action is invoked with at {string}') do |target|
  cmd = Aethyr::Core::Actions::Look::LookCommand.new(@look_player, at: target)
  cmd.action
  @look_command = cmd
end

When('the LookCommand action is invoked with in {string}') do |target|
  cmd = Aethyr::Core::Actions::Look::LookCommand.new(@look_player, in: target)
  cmd.action
  @look_command = cmd
end

When('the LookCommand action is invoked looking at self') do
  # Register the player so search_inv or room.find returns the player itself
  @look_player.register_inv("self", @look_player)
  cmd = Aethyr::Core::Actions::Look::LookCommand.new(@look_player, at: "self")
  cmd.action
  @look_command = cmd
end

When('the LookCommand action is invoked expecting error') do
  cmd = Aethyr::Core::Actions::Look::LookCommand.new(@look_player)
  begin
    cmd.action
  rescue => e
    @look_error = e
  end
  @look_command = cmd
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the look player should see {string}') do |fragment|
  match = @look_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@look_player.messages.inspect}")
end

Then('the look command should have raised an error') do
  assert(@look_error,
    "Expected LookCommand to raise an error but it did not")
end

Then('the look in target should have received look_inside') do
  assert(@look_in_target.looked_inside,
    "Expected look_inside to have been called on the target")
end
