# frozen_string_literal: true
###############################################################################
# Step definitions for TerrainCommand action coverage.                        #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/terrain'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module TerrainCommandWorld
  attr_accessor :terrain_player, :terrain_target, :terrain_setting,
                :terrain_value, :terrain_room, :terrain_has_area
end
World(TerrainCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class TerrainCommandPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "room_goid_1"
    @name      = "TestAdmin"
    @goid      = "player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Info bag that supports dynamic terrain attribute storage.
class TerrainInfoBag < OpenStruct; end

# Minimal area double for the room's area.
class TerrainCommandArea
  attr_accessor :name, :info

  def initialize(name = "TestArea")
    @name = name
    @info = TerrainInfoBag.new(terrain: TerrainInfoBag.new)
  end

  def nil?
    false
  end
end

# Minimal room double for the player's current room.
class TerrainCommandRoom
  attr_accessor :name, :goid, :info, :area

  def initialize(name = "Test Room")
    @name = name
    @goid = "room_goid_1"
    @info = TerrainInfoBag.new(terrain: TerrainInfoBag.new)
    @area = nil
  end

  def to_s
    @name
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed TerrainCommand environment') do
  @terrain_player   = TerrainCommandPlayer.new
  @terrain_target   = nil
  @terrain_setting  = nil
  @terrain_value    = nil
  @terrain_has_area = false

  @terrain_room = TerrainCommandRoom.new("Test Room")
  @terrain_player.container = @terrain_room.goid

  room_ref = @terrain_room

  mgr = Object.new
  mgr.define_singleton_method(:get_object) do |goid|
    if goid == room_ref.goid
      room_ref
    else
      nil
    end
  end

  $manager = mgr
end

Given('the room has an area') do
  @terrain_has_area = true
  @terrain_room.area = TerrainCommandArea.new("TestArea")
end

Given('the terrain target is {string}') do |target|
  @terrain_target = target
end

Given('the terrain setting is {string}') do |setting|
  @terrain_setting = setting
end

Given('the terrain value is {string}') do |value|
  @terrain_value = value
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the TerrainCommand action is invoked') do
  data = {}
  data[:target]  = @terrain_target  if @terrain_target
  data[:setting] = @terrain_setting if @terrain_setting
  data[:value]   = @terrain_value   if @terrain_value

  cmd = Aethyr::Core::Actions::Terrain::TerrainCommand.new(@terrain_player, **data)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the terrain player should see {string}') do |fragment|
  match = @terrain_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@terrain_player.messages.inspect}")
end
