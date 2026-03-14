# frozen_string_literal: true
###############################################################################
# Step definitions for MapCommand action coverage.                            #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/map'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module - scenario-scoped state                                        #
###############################################################################
module MapCommandWorld
  attr_accessor :map_player, :map_room
end
World(MapCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class MapCommandMockPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "map_room_goid_1"
    @name      = "MapTestPlayer"
    @goid      = "map_player_goid_1"
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

# Mock area that responds to render_map and position
class MapCommandMockArea
  def position(_room)
    [0, 0]
  end

  def render_map(_player, _position)
    "rendered map output"
  end
end

# Mock room returned by $manager.get_object
class MapCommandMockRoom
  attr_accessor :name, :area

  def initialize
    @name = "MapTestRoom"
    @area = MapCommandMockArea.new
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed MapCommand environment') do
  @map_player = MapCommandMockPlayer.new
  @map_room   = MapCommandMockRoom.new

  # Ensure `log` is available as a no-op
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  player_ref = @map_player
  room_ref   = @map_room

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

###############################################################################
# When steps                                                                  #
###############################################################################
When('the MapCommand action is invoked') do
  cmd = Aethyr::Core::Actions::Map::MapCommand.new(@map_player)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the map command player should see {string}') do |fragment|
  match = @map_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected map command player output containing #{fragment.inspect}, got: #{@map_player.messages.inspect}")
end
