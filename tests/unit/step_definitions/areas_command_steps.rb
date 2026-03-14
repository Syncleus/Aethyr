# frozen_string_literal: true
###############################################################################
# Step definitions for AreasCommand action coverage.                          #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/areas'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# Ensure bare Area and Room constants exist for areas.rb find_all calls       #
###############################################################################
unless defined?(Area)
  Area = Class.new
end

unless defined?(Room)
  Room = Class.new
end

###############################################################################
# World module - scenario-scoped state                                        #
###############################################################################
module AreasCommandWorld
  attr_accessor :areas_player, :areas_room, :areas_find_all_result
end
World(AreasCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AreasCommandMockPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "areas_room_goid_1"
    @name      = "AreasTestPlayer"
    @goid      = "areas_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    if msg.is_a?(Array)
      msg.each { |m| @messages << m.to_s }
    else
      @messages << msg.to_s
    end
  end
end

# Mock room returned by $manager.get_object
class AreasCommandMockRoom
  attr_accessor :name

  def initialize
    @name = "AreasTestRoom"
  end
end

# Mock area object with inventory, info, and terrain
class AreasCommandMockArea
  attr_reader :name, :inventory, :info

  def initialize(name, room_count, area_type)
    @name      = name
    @inventory = AreasCommandMockInventory.new(room_count)
    @info      = OpenStruct.new(terrain: OpenStruct.new(area_type: area_type))
  end
end

# Mock inventory that responds to find_all('class', Room)
class AreasCommandMockInventory
  def initialize(room_count)
    @room_count = room_count
  end

  def find_all(_attrib, _klass)
    Array.new(@room_count) { Object.new }
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AreasCommand environment') do
  @areas_player          = AreasCommandMockPlayer.new
  @areas_room            = AreasCommandMockRoom.new
  @areas_find_all_result = []

  # Ensure `log` is available as a no-op
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  player_ref  = @areas_player
  room_ref    = @areas_room
  areas_world = self

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref
    else
      nil
    end
  end

  mgr.define_singleton_method(:find_all) do |_attrib, _query|
    areas_world.areas_find_all_result
  end

  $manager = mgr
end

Given('the areas manager find_all returns no areas') do
  @areas_find_all_result = []
end

Given('the areas manager find_all returns one area named {string} with {int} rooms and terrain {string}') do |name, room_count, terrain|
  @areas_find_all_result = [
    AreasCommandMockArea.new(name, room_count, terrain)
  ]
end

Given('the areas manager find_all returns multiple areas') do
  @areas_find_all_result = [
    AreasCommandMockArea.new("Forest", 5, "forest"),
    AreasCommandMockArea.new("Desert", 2, "arid")
  ]
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AreasCommand action is invoked') do
  cmd = Aethyr::Core::Actions::Areas::AreasCommand.new(@areas_player)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the areas player should see {string}') do |fragment|
  match = @areas_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected areas player output containing #{fragment.inspect}, got: #{@areas_player.messages.inspect}")
end
