# frozen_string_literal: true
###############################################################################
# Step definitions for ByeHandler player_input coverage.                      #
#                                                                             #
# These steps exercise the input-parsing regex branches inside                #
# ByeHandler#player_input (lines 35-42 of bye.rb) to ensure the when-branch  #
# dispatches the correct ByeCommand action with the right parameters.         #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/input_handlers/emotes/bye'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module ByeHandlerWorld
  attr_accessor :bye_h_player, :bye_h_handler, :bye_h_captured_actions
end
World(ByeHandlerWorld)

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed ByeHandler input environment') do
  @bye_h_player = ::Aethyr::Core::Objects::MockPlayer.new("ByeTestPlayer")

  @bye_h_handler = Aethyr::Core::Commands::Bye::ByeHandler.new(@bye_h_player)

  mgr = Object.new
  captured = []
  mgr.define_singleton_method(:submit_action) { |action| captured << action }
  $manager = mgr

  @bye_h_captured_actions = captured
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the bye handler input is {string}') do |input|
  @bye_h_captured_actions.clear
  @bye_h_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the bye handler should have submitted {int} action(s)') do |count|
  assert_equal(count, @bye_h_captured_actions.size,
    "Expected #{count} submitted action(s), got #{@bye_h_captured_actions.size}")
end

Then('the submitted bye handler action should be a ByeCommand') do
  action = @bye_h_captured_actions.last
  assert_instance_of(Aethyr::Core::Actions::Bye::ByeCommand, action,
    "Expected a ByeCommand, got #{action.class}")
end

Then('the submitted bye handler action object should be nil') do
  action = @bye_h_captured_actions.last
  assert_nil(action.object,
    "Expected object to be nil, got #{action.object.inspect}")
end

Then('the submitted bye handler action object should be {string}') do |expected|
  action = @bye_h_captured_actions.last
  assert_equal(expected, action.object,
    "Expected object '#{expected}', got '#{action.object.inspect}'")
end

Then('the submitted bye handler action post should be nil') do
  action = @bye_h_captured_actions.last
  assert_nil(action.post,
    "Expected post to be nil, got #{action.post.inspect}")
end

Then('the submitted bye handler action post should be {string}') do |expected|
  action = @bye_h_captured_actions.last
  assert_equal(expected, action.post,
    "Expected post '#{expected}', got '#{action.post.inspect}'")
end
