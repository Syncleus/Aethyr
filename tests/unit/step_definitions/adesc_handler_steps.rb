# frozen_string_literal: true
###############################################################################
# Step definitions for AdescHandler player_input coverage.                    #
#                                                                             #
# These steps specifically exercise the input-parsing regex branches inside   #
# AdescHandler#player_input (lines 38-46 of adesc.rb) which are NOT covered  #
# by the existing AdescCommand action tests.                                  #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/input_handlers/admin/adesc'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AdescHandlerWorld
  attr_accessor :adesc_h_player, :adesc_h_handler, :adesc_h_captured_actions
end
World(AdescHandlerWorld)

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AdescHandler input environment') do
  @adesc_h_player = ::Aethyr::Core::Objects::MockPlayer.new("AdescAdmin")
  @adesc_h_player.admin = true

  @adesc_h_handler = Aethyr::Core::Commands::Adesc::AdescHandler.new(@adesc_h_player)

  mgr = Object.new
  captured = []
  mgr.define_singleton_method(:submit_action) { |action| captured << action }
  $manager = mgr

  @adesc_h_captured_actions = captured
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the adesc handler input is {string}') do |input|
  @adesc_h_captured_actions.clear
  @adesc_h_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the adesc handler should have submitted {int} action(s)') do |count|
  assert_equal(count, @adesc_h_captured_actions.size,
    "Expected #{count} submitted action(s), got #{@adesc_h_captured_actions.size}")
end

Then('the submitted adesc action should have object {string}') do |expected|
  action = @adesc_h_captured_actions.last
  assert_not_nil(action, "Expected a submitted action but none was captured")
  assert_equal(expected, action[:object],
    "Expected object '#{expected}', got '#{action[:object]}'")
end

Then('the submitted adesc action should have desc {string}') do |expected|
  action = @adesc_h_captured_actions.last
  assert_not_nil(action, "Expected a submitted action but none was captured")
  assert_equal(expected, action[:desc],
    "Expected desc '#{expected}', got '#{action[:desc]}'")
end

Then('the submitted adesc action should have inroom true') do
  action = @adesc_h_captured_actions.last
  assert_not_nil(action, "Expected a submitted action but none was captured")
  assert_equal(true, action[:inroom],
    "Expected inroom to be true, got '#{action[:inroom]}'")
end
