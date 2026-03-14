# frozen_string_literal: true
###############################################################################
# Step definitions for BackHandler player_input coverage.                     #
#                                                                             #
# These steps exercise the input-parsing regex branches inside                #
# BackHandler#player_input (lines 35-42 of back.rb) which are NOT covered    #
# by the existing BackCommand action tests.                                   #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/input_handlers/emotes/back'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module BackHandlerWorld
  attr_accessor :back_h_player, :back_h_handler, :back_h_captured_actions
end
World(BackHandlerWorld)

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed BackHandler input environment') do
  @back_h_player = ::Aethyr::Core::Objects::MockPlayer.new("TestPlayer")

  @back_h_handler = Aethyr::Core::Commands::Back::BackHandler.new(@back_h_player)

  mgr = Object.new
  captured = []
  mgr.define_singleton_method(:submit_action) { |action| captured << action }
  $manager = mgr

  @back_h_captured_actions = captured
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the back handler input is {string}') do |input|
  @back_h_captured_actions.clear
  @back_h_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the back handler should have submitted {int} action(s)') do |count|
  assert_equal(count, @back_h_captured_actions.size,
    "Expected #{count} submitted action(s), got #{@back_h_captured_actions.size}")
end

Then('the submitted back action object should be {string}') do |expected|
  action = @back_h_captured_actions.last
  assert(action, 'No action was submitted')
  assert_equal(expected, action.object,
    "Expected object '#{expected}', got '#{action.object.inspect}'")
end

Then('the submitted back action object should be nil') do
  action = @back_h_captured_actions.last
  assert(action, 'No action was submitted')
  assert_nil(action.object,
    "Expected object to be nil, got '#{action.object.inspect}'")
end

Then('the submitted back action post should be {string}') do |expected|
  action = @back_h_captured_actions.last
  assert(action, 'No action was submitted')
  assert_equal(expected, action.post,
    "Expected post '#{expected}', got '#{action.post.inspect}'")
end

Then('the submitted back action post should be nil') do
  action = @back_h_captured_actions.last
  assert(action, 'No action was submitted')
  assert_nil(action.post,
    "Expected post to be nil, got '#{action.post.inspect}'")
end
