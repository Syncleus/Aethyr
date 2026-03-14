# frozen_string_literal: true
###############################################################################
# Step definitions for BrbHandler player_input coverage.                      #
#                                                                             #
# These steps exercise the input-parsing regex branches inside                #
# BrbHandler#player_input (lines 35-43 of emotes/brb.rb) to ensure the       #
# when-branch dispatches the correct BrbCommand action with the expected      #
# :object and :post attributes.                                               #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/input_handlers/emotes/brb'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module BrbHandlerWorld
  attr_accessor :brb_h_player, :brb_h_handler, :brb_h_captured_actions
end
World(BrbHandlerWorld)

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed BrbHandler input environment') do
  @brb_h_player = ::Aethyr::Core::Objects::MockPlayer.new("BrbTestPlayer")

  @brb_h_handler = Aethyr::Core::Commands::Brb::BrbHandler.new(@brb_h_player)

  mgr = Object.new
  captured = []
  mgr.define_singleton_method(:submit_action) { |action| captured << action }
  $manager = mgr

  @brb_h_captured_actions = captured
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the brb handler input is {string}') do |input|
  @brb_h_captured_actions.clear
  @brb_h_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the brb handler should have submitted {int} action(s)') do |count|
  assert_equal(count, @brb_h_captured_actions.size,
    "Expected #{count} submitted action(s), got #{@brb_h_captured_actions.size}")
end

Then('the submitted brb handler action should be a BrbCommand') do
  action = @brb_h_captured_actions.last
  assert_instance_of(Aethyr::Core::Actions::Brb::BrbCommand, action,
    "Expected a BrbCommand, got #{action.class}")
end

Then('the submitted brb handler action object should be nil') do
  action = @brb_h_captured_actions.last
  assert_nil(action.object,
    "Expected object to be nil, got #{action.object.inspect}")
end

Then('the submitted brb handler action object should be {string}') do |expected|
  action = @brb_h_captured_actions.last
  assert_equal(expected, action.object,
    "Expected object '#{expected}', got '#{action.object.inspect}'")
end

Then('the submitted brb handler action post should be nil') do
  action = @brb_h_captured_actions.last
  assert_nil(action.post,
    "Expected post to be nil, got #{action.post.inspect}")
end

Then('the submitted brb handler action post should be {string}') do |expected|
  action = @brb_h_captured_actions.last
  assert_equal(expected, action.post,
    "Expected post '#{expected}', got '#{action.post.inspect}'")
end
