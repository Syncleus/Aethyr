# frozen_string_literal: true
###############################################################################
# Step definitions for AsetHandler player_input coverage.                     #
#                                                                             #
# These steps specifically exercise the input-parsing regex branches inside   #
# AsetHandler#player_input (lines 39-48 of aset.rb) which are NOT covered    #
# by the existing AsetCommand action tests.                                   #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/input_handlers/admin/aset'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AsetHandlerWorld
  attr_accessor :aset_h_player, :aset_h_handler, :aset_h_captured_actions
end
World(AsetHandlerWorld)

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AsetHandler input environment') do
  @aset_h_player = ::Aethyr::Core::Objects::MockPlayer.new("AsetAdmin")
  @aset_h_player.admin = true

  @aset_h_handler = Aethyr::Core::Commands::Aset::AsetHandler.new(@aset_h_player)

  mgr = Object.new
  captured = []
  mgr.define_singleton_method(:submit_action) { |action| captured << action }
  $manager = mgr

  @aset_h_captured_actions = captured
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the admin handler input is {string}') do |input|
  @aset_h_captured_actions.clear
  @aset_h_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the aset handler should have submitted {int} action(s)') do |count|
  assert_equal(count, @aset_h_captured_actions.size,
    "Expected #{count} submitted action(s), got #{@aset_h_captured_actions.size}")
end

Then('the submitted aset action should have object {string}') do |expected|
  action = @aset_h_captured_actions.last
  assert_equal(expected, action.object,
    "Expected object '#{expected}', got '#{action.object}'")
end

Then('the submitted aset action should have attribute {string}') do |expected|
  action = @aset_h_captured_actions.last
  assert_equal(expected, action.attribute,
    "Expected attribute '#{expected}', got '#{action.attribute}'")
end

Then('the submitted aset action should have value {string}') do |expected|
  action = @aset_h_captured_actions.last
  assert_equal(expected, action.value,
    "Expected value '#{expected}', got '#{action.value}'")
end

Then('the submitted aset action should have force') do
  action = @aset_h_captured_actions.last
  assert_equal(true, action.force,
    "Expected force to be true, got #{action.force.inspect}")
end

Then('the submitted aset action should not have force') do
  action = @aset_h_captured_actions.last
  assert_nil(action.force,
    "Expected force to be nil, got #{action.force.inspect}")
end
