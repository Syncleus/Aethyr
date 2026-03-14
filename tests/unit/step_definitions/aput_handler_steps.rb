# frozen_string_literal: true
###############################################################################
# Step definitions for AputHandler player_input coverage.                     #
#                                                                             #
# These steps specifically exercise the input-parsing regex branches inside   #
# AputHandler#player_input (lines 38-46 of aput.rb) which are NOT covered    #
# by the existing AputCommand action tests.                                   #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/input_handlers/admin/aput'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AputHandlerWorld
  attr_accessor :aput_h_player, :aput_h_handler, :aput_h_captured_actions
end
World(AputHandlerWorld)

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AputHandler input environment') do
  @aput_h_player = ::Aethyr::Core::Objects::MockPlayer.new("AputAdmin")
  @aput_h_player.admin = true

  @aput_h_handler = Aethyr::Core::Commands::Aput::AputHandler.new(@aput_h_player)

  mgr = Object.new
  captured = []
  mgr.define_singleton_method(:submit_action) { |action| captured << action }
  $manager = mgr

  @aput_h_captured_actions = captured
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the aput handler input is {string}') do |input|
  @aput_h_captured_actions.clear
  @aput_h_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the aput handler should have submitted {int} action(s)') do |count|
  assert_equal(count, @aput_h_captured_actions.size,
    "Expected #{count} submitted action(s), got #{@aput_h_captured_actions.size}")
end

Then('the submitted aput action should have object {string}') do |expected|
  action = @aput_h_captured_actions.last
  assert_equal(expected, action[:object],
    "Expected object '#{expected}', got '#{action[:object]}'")
end

Then('the submitted aput action should have in {string}') do |expected|
  action = @aput_h_captured_actions.last
  assert_equal(expected, action[:in],
    "Expected in '#{expected}', got '#{action[:in]}'")
end

Then('the submitted aput action should have at {string}') do |expected|
  action = @aput_h_captured_actions.last
  assert_equal(expected, action[:at],
    "Expected at '#{expected}', got '#{action[:at]}'")
end
