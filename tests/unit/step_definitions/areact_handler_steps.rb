# frozen_string_literal: true
###############################################################################
# Step definitions for AreactHandler (input handler) coverage.                #
#                                                                             #
# These tests exercise the player_input method of AreactHandler, ensuring     #
# that textual commands are correctly parsed and dispatched as                 #
# AreactionCommand objects via $manager.submit_action.                        #
###############################################################################

require 'test/unit/assertions'
require 'aethyr/core/input_handlers/admin/areact'
require 'aethyr/core/actions/commands/areaction'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module - scenario-scoped state                                        #
###############################################################################
module AreactHandlerWorld
  attr_accessor :areact_player, :areact_handler, :areact_captured_actions
end
World(AreactHandlerWorld)

###############################################################################
# StubManager for capturing submitted actions                                 #
###############################################################################
unless defined?(AreactStubManager)
  class AreactStubManager
    attr_reader :actions

    def initialize
      @actions = []
    end

    def submit_action(action)
      @actions << action
    end
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AreactHandler environment') do
  @areact_player = ::Aethyr::Core::Objects::MockPlayer.new
  @areact_player.admin = true

  # Install a stub manager that records submitted actions.
  $manager = AreactStubManager.new
  @areact_captured_actions = $manager.actions

  # Instantiate the handler under test.
  @areact_handler = Aethyr::Core::Commands::Areact::AreactHandler.new(@areact_player)
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the admin enters {string}') do |input|
  @areact_captured_actions.clear
  @areact_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the manager should receive an AreactionCommand') do
  assert(!@areact_captured_actions.empty?,
    'No actions were captured - submit_action was not invoked')
  action = @areact_captured_actions.last
  assert_instance_of(Aethyr::Core::Actions::Areaction::AreactionCommand, action,
    "Expected an AreactionCommand but received #{action.class}")
end

Then('the manager should not receive any action') do
  assert(@areact_captured_actions.empty?,
    "Expected no actions but captured: #{@areact_captured_actions.inspect}")
end

Then('the submitted areaction command should be {string}') do |expected_command|
  action = @areact_captured_actions.last
  assert_equal(expected_command, action[:command],
    "Expected command '#{expected_command}' but got '#{action[:command]}'")
end

Then('the submitted areaction object should be {string}') do |expected_object|
  action = @areact_captured_actions.last
  assert_equal(expected_object, action[:object],
    "Expected object '#{expected_object}' but got '#{action[:object]}'")
end

Then('the submitted areaction file should be {string}') do |expected_file|
  action = @areact_captured_actions.last
  assert_equal(expected_file, action[:file],
    "Expected file '#{expected_file}' but got '#{action[:file]}'")
end

Then('the submitted areaction action_name should be {string}') do |expected_action_name|
  action = @areact_captured_actions.last
  assert_equal(expected_action_name, action[:action_name],
    "Expected action_name '#{expected_action_name}' but got '#{action[:action_name]}'")
end
