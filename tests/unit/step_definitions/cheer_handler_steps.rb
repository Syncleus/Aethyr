# frozen_string_literal: true
###############################################################################
# Step definitions for CheerHandler player_input coverage.                    #
#                                                                             #
# These steps exercise the input-parsing regex branches inside                #
# CheerHandler#player_input (lines 35-42 of cheer.rb) which are NOT covered  #
# by the existing CheerCommand action tests.                                  #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/input_handlers/emotes/cheer'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module CheerHandlerWorld
  attr_accessor :cheer_h_player, :cheer_h_handler, :cheer_h_captured_actions
end
World(CheerHandlerWorld)

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed CheerHandler input environment') do
  @cheer_h_player = ::Aethyr::Core::Objects::MockPlayer.new("TestPlayer")

  @cheer_h_handler = Aethyr::Core::Commands::Cheer::CheerHandler.new(@cheer_h_player)

  mgr = Object.new
  captured = []
  mgr.define_singleton_method(:submit_action) { |action| captured << action }
  $manager = mgr

  @cheer_h_captured_actions = captured
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the cheer handler input is {string}') do |input|
  @cheer_h_captured_actions.clear
  @cheer_h_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the cheer handler should have submitted {int} action(s)') do |count|
  assert_equal(count, @cheer_h_captured_actions.size,
    "Expected #{count} submitted action(s), got #{@cheer_h_captured_actions.size}")
end

Then('the submitted cheer action object should be {string}') do |expected|
  action = @cheer_h_captured_actions.last
  assert(action, 'No action was submitted')
  assert_equal(expected, action.object,
    "Expected object '#{expected}', got '#{action.object.inspect}'")
end

Then('the submitted cheer action object should be nil') do
  action = @cheer_h_captured_actions.last
  assert(action, 'No action was submitted')
  assert_nil(action.object,
    "Expected object to be nil, got '#{action.object.inspect}'")
end

Then('the submitted cheer action post should be {string}') do |expected|
  action = @cheer_h_captured_actions.last
  assert(action, 'No action was submitted')
  assert_equal(expected, action.post,
    "Expected post '#{expected}', got '#{action.post.inspect}'")
end

Then('the submitted cheer action post should be nil') do
  action = @cheer_h_captured_actions.last
  assert(action, 'No action was submitted')
  assert_nil(action.post,
    "Expected post to be nil, got '#{action.post.inspect}'")
end
