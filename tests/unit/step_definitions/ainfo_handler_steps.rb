# frozen_string_literal: true
###############################################################################
# Step definitions for AinfoHandler player_input coverage.                    #
#                                                                             #
# These steps specifically exercise the input-parsing regex branches inside   #
# AinfoHandler#player_input (lines 38-53 of ainfo.rb) which are NOT covered  #
# by the existing AinfoCommand action tests.                                  #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/input_handlers/admin/ainfo'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AinfoHandlerWorld
  attr_accessor :ainfo_h_player, :ainfo_h_handler, :ainfo_h_captured_actions
end
World(AinfoHandlerWorld)

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AinfoHandler input environment') do
  @ainfo_h_player = ::Aethyr::Core::Objects::MockPlayer.new("AinfoAdmin")
  @ainfo_h_player.admin = true

  @ainfo_h_handler = Aethyr::Core::Commands::Ainfo::AinfoHandler.new(@ainfo_h_player)

  mgr = Object.new
  captured = []
  mgr.define_singleton_method(:submit_action) { |action| captured << action }
  $manager = mgr

  @ainfo_h_captured_actions = captured
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the ainfo handler input is {string}') do |input|
  @ainfo_h_captured_actions.clear
  @ainfo_h_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the ainfo handler should have submitted {int} action(s)') do |count|
  assert_equal(count, @ainfo_h_captured_actions.size,
    "Expected #{count} submitted action(s), got #{@ainfo_h_captured_actions.size}")
end

Then('the submitted ainfo action should have command {string}') do |expected|
  action = @ainfo_h_captured_actions.last
  assert_equal(expected, action[:command],
    "Expected command '#{expected}', got '#{action[:command]}'")
end

Then('the submitted ainfo action should have object {string}') do |expected|
  action = @ainfo_h_captured_actions.last
  assert_equal(expected, action[:object],
    "Expected object '#{expected}', got '#{action[:object]}'")
end

Then('the submitted ainfo action should have attrib {string}') do |expected|
  action = @ainfo_h_captured_actions.last
  assert_equal(expected, action[:attrib],
    "Expected attrib '#{expected}', got '#{action[:attrib]}'")
end

Then('the submitted ainfo action should have value {string}') do |expected|
  action = @ainfo_h_captured_actions.last
  assert_equal(expected, action[:value],
    "Expected value '#{expected}', got '#{action[:value]}'")
end
