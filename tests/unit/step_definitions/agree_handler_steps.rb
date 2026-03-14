# frozen_string_literal: true
################################################################################
# Step definitions for AgreeHandler input-handler tests.                       #
#                                                                              #
# Tests the player_input method of AgreeHandler to ensure it correctly parses  #
# textual input and submits the appropriate AgreeCommand via $manager.          #
################################################################################

require 'test/unit/assertions'
require 'aethyr/core/input_handlers/emotes/agree'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# Shared state                                                                #
###############################################################################
module AgreeHandlerWorld
  attr_accessor :agree_handler, :agree_player, :agree_captured_actions
end
World(AgreeHandlerWorld)

###############################################################################
# Stub manager – captures submitted actions                                   #
###############################################################################
class AgreeHandlerStubManager
  attr_reader :actions

  def initialize
    @actions = []
  end

  def submit_action(action)
    @actions << action
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AgreeHandler environment') do
  @agree_player  = ::Aethyr::Core::Objects::MockPlayer.new('TestPlayer')
  @agree_handler = Aethyr::Core::Commands::Agree::AgreeHandler.new(@agree_player)

  $manager = AgreeHandlerStubManager.new
  @agree_captured_actions = $manager.actions
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the agree handler receives input {string}') do |input|
  @agree_captured_actions.clear
  @agree_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the manager should receive an AgreeCommand') do
  assert(!@agree_captured_actions.empty?,
    'No actions were captured – submit_action was not invoked')
  action = @agree_captured_actions.last
  assert_instance_of(Aethyr::Core::Actions::Agree::AgreeCommand, action,
    "Expected an AgreeCommand but received #{action.class}")
end

Then('the agree handler manager should not receive any action') do
  assert(@agree_captured_actions.empty?,
    "Expected no actions but got #{@agree_captured_actions.length}")
end

Then('the AgreeCommand should have no object') do
  action = @agree_captured_actions.last
  params = action.to_h
  assert_nil(params[:object], "Expected :object to be nil but got #{params[:object].inspect}")
end

Then('the AgreeCommand should have no post') do
  action = @agree_captured_actions.last
  params = action.to_h
  assert_nil(params[:post], "Expected :post to be nil but got #{params[:post].inspect}")
end

Then('the AgreeCommand object should be {string}') do |expected|
  action = @agree_captured_actions.last
  params = action.to_h
  assert_equal(expected, params[:object],
    "Expected :object to be '#{expected}' but got #{params[:object].inspect}")
end

Then('the AgreeCommand post should be {string}') do |expected|
  action = @agree_captured_actions.last
  params = action.to_h
  assert_equal(expected, params[:post],
    "Expected :post to be '#{expected}' but got #{params[:post].inspect}")
end
