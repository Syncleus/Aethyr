# frozen_string_literal: true
###############################################################################
# Step definitions for SetHandler player_input coverage.                      #
#                                                                             #
# These steps exercise the input-parsing regex branches inside                #
# SetHandler#player_input (lines 54-72 of set.rb) to ensure each when-branch #
# dispatches the correct command action.                                      #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/input_handlers/set'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module SetHandlerWorld
  attr_accessor :set_h_player, :set_h_handler, :set_h_captured_actions
end
World(SetHandlerWorld)

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed SetHandler input environment') do
  @set_h_player = ::Aethyr::Core::Objects::MockPlayer.new("SetTestPlayer")

  @set_h_handler = Aethyr::Core::Commands::Set::SetHandler.new(@set_h_player)

  mgr = Object.new
  captured = []
  mgr.define_singleton_method(:submit_action) { |action| captured << action }
  $manager = mgr

  @set_h_captured_actions = captured
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the set handler input is {string}') do |input|
  @set_h_captured_actions.clear
  @set_h_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the set handler should have submitted {int} action(s)') do |count|
  assert_equal(count, @set_h_captured_actions.size,
    "Expected #{count} submitted action(s), got #{@set_h_captured_actions.size}")
end

Then('the submitted set handler action should be a SetcolorCommand') do
  action = @set_h_captured_actions.last
  assert_instance_of(Aethyr::Core::Actions::Setcolor::SetcolorCommand, action,
    "Expected a SetcolorCommand, got #{action.class}")
end

Then('the submitted set handler action should be a ShowcolorsCommand') do
  action = @set_h_captured_actions.last
  assert_instance_of(Aethyr::Core::Actions::Showcolors::ShowcolorsCommand, action,
    "Expected a ShowcolorsCommand, got #{action.class}")
end

Then('the submitted set handler action should be a SetpasswordCommand') do
  action = @set_h_captured_actions.last
  assert_instance_of(Aethyr::Core::Actions::Setpassword::SetpasswordCommand, action,
    "Expected a SetpasswordCommand, got #{action.class}")
end

Then('the submitted set handler action should be a SetCommand') do
  action = @set_h_captured_actions.last
  assert_instance_of(Aethyr::Core::Actions::Set::SetCommand, action,
    "Expected a SetCommand, got #{action.class}")
end

Then('the submitted set handler action should have option {string}') do |expected|
  action = @set_h_captured_actions.last
  assert_equal(expected, action.option,
    "Expected option '#{expected}', got '#{action.option}'")
end

Then('the submitted set handler action should not have color') do
  action = @set_h_captured_actions.last
  assert_nil(action.color,
    "Expected color to be nil, got #{action.color.inspect}")
end

Then('the submitted set handler action should have setting {string}') do |expected|
  action = @set_h_captured_actions.last
  assert_equal(expected, action.setting,
    "Expected setting '#{expected}', got '#{action.setting}'")
end

Then('the submitted set handler action should have value {string}') do |expected|
  action = @set_h_captured_actions.last
  assert_equal(expected, action.value,
    "Expected value '#{expected}', got '#{action.value}'")
end
