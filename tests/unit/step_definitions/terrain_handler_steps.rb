# frozen_string_literal: true
###############################################################################
# Step definitions for TerrainHandler player_input coverage.                  #
#                                                                             #
# These steps specifically exercise the input-parsing regex branches inside   #
# TerrainHandler#player_input (lines 35-48 of terrain.rb) which are NOT      #
# covered by the existing TerrainCommand action tests.                        #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/input_handlers/admin/terrain'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module TerrainHandlerWorld
  attr_accessor :terrain_h_player, :terrain_h_handler, :terrain_h_captured_actions
end
World(TerrainHandlerWorld)

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed TerrainHandler input environment') do
  @terrain_h_player = ::Aethyr::Core::Objects::MockPlayer.new("TerrainAdmin")
  @terrain_h_player.admin = true

  @terrain_h_handler = Aethyr::Core::Commands::Terrain::TerrainHandler.new(@terrain_h_player)

  mgr = Object.new
  captured = []
  mgr.define_singleton_method(:submit_action) { |action| captured << action }
  $manager = mgr

  @terrain_h_captured_actions = captured
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the terrain handler input is {string}') do |input|
  @terrain_h_captured_actions.clear
  @terrain_h_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the terrain handler should have submitted {int} action(s)') do |count|
  assert_equal(count, @terrain_h_captured_actions.size,
    "Expected #{count} submitted action(s), got #{@terrain_h_captured_actions.size}")
end

Then('the submitted terrain action should have target {string}') do |expected|
  action = @terrain_h_captured_actions.last
  assert_equal(expected, action[:target],
    "Expected target '#{expected}', got '#{action[:target]}'")
end

Then('the submitted terrain action should have setting {string}') do |expected|
  action = @terrain_h_captured_actions.last
  assert_equal(expected, action[:setting],
    "Expected setting '#{expected}', got '#{action[:setting]}'")
end

Then('the submitted terrain action should have value {string}') do |expected|
  action = @terrain_h_captured_actions.last
  assert_equal(expected, action[:value],
    "Expected value '#{expected}', got '#{action[:value]}'")
end
