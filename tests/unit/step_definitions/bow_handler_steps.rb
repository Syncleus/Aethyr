# frozen_string_literal: true
###############################################################################
# Step definitions for BowHandler player_input coverage.                      #
#                                                                             #
# These steps exercise the regex branch inside                                #
# BowHandler#player_input (lines 35-42 of bow.rb) to achieve >97% line       #
# coverage.                                                                   #
#                                                                             #
# All collaborators ($manager, player) are stubbed to isolate the handler     #
# logic under test.                                                           #
###############################################################################

require 'test/unit/assertions'
require 'aethyr/core/input_handlers/emotes/bow'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module BowHandlerWorld
  attr_accessor :bh_player, :bh_handler, :bh_captured_actions
end
World(BowHandlerWorld)

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed BowHandler environment') do
  @bh_player = ::Aethyr::Core::Objects::MockPlayer.new("BowTester")

  @bh_handler = Aethyr::Core::Commands::Bow::BowHandler.new(@bh_player)

  # Lightweight manager stub that captures submitted actions.
  mgr = Object.new
  captured = []
  mgr.define_singleton_method(:submit_action) { |action| captured << action }
  $manager = mgr

  @bh_captured_actions = captured
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the bow handler input is {string}') do |input|
  @bh_captured_actions.clear
  @bh_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the bow handler should have submitted {int} action(s)') do |count|
  assert_equal(count, @bh_captured_actions.size,
    "Expected #{count} submitted action(s), got #{@bh_captured_actions.size}")
end

Then('the submitted bow action should be a BowCommand') do
  action = @bh_captured_actions.last
  assert_instance_of(
    Aethyr::Core::Actions::Bow::BowCommand,
    action,
    "Expected BowCommand but got #{action.class}"
  )
end

Then('the submitted bow action object should be nil') do
  action = @bh_captured_actions.last
  assert_nil(action[:object],
    "Expected object to be nil, got #{action[:object].inspect}")
end

Then('the submitted bow action object should be {string}') do |expected|
  action = @bh_captured_actions.last
  assert_equal(expected, action[:object],
    "Expected object '#{expected}', got '#{action[:object]}'")
end

Then('the submitted bow action post should be nil') do
  action = @bh_captured_actions.last
  assert_nil(action[:post],
    "Expected post to be nil, got #{action[:post].inspect}")
end

Then('the submitted bow action post should be {string}') do |expected|
  action = @bh_captured_actions.last
  assert_equal(expected, action[:post],
    "Expected post '#{expected}', got '#{action[:post]}'")
end
