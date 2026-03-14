# frozen_string_literal: true
################################################################################
# Step definitions for BlushHandler – the input handler that parses player     #
# text and dispatches BlushCommand actions via $manager.submit_action.         #
################################################################################

require 'test/unit/assertions'
require 'aethyr/core/input_handlers/emotes/blush'
require 'aethyr/core/actions/commands/emotes/blush'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# Shared state for BlushHandler scenarios                                     #
###############################################################################
module BlushHandlerWorld
  attr_accessor :blush_player, :blush_handler, :blush_captured_actions
end
World(BlushHandlerWorld)

###############################################################################
# Lightweight stub manager to capture submitted actions                       #
###############################################################################
class BlushHandlerStubManager
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
Given('a stubbed BlushHandler environment') do
  @blush_player = ::Aethyr::Core::Objects::MockPlayer.new('TestPlayer')
  @blush_handler = Aethyr::Core::Commands::Blush::BlushHandler.new(@blush_player)

  $manager = BlushHandlerStubManager.new
  @blush_captured_actions = $manager.actions
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the blush handler receives input {string}') do |input|
  @blush_captured_actions.clear
  @blush_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the manager should receive a BlushCommand') do
  assert(!@blush_captured_actions.empty?,
    'No actions were captured – submit_action was not invoked')
  action = @blush_captured_actions.last
  assert_instance_of(Aethyr::Core::Actions::Blush::BlushCommand, action,
    "Expected a BlushCommand but received #{action.class}")
end

Then('the BlushCommand should have no object') do
  action = @blush_captured_actions.last
  params = action.to_h
  assert_nil(params[:object], "Expected :object to be nil but got #{params[:object].inspect}")
end

Then('the BlushCommand should have no post') do
  action = @blush_captured_actions.last
  params = action.to_h
  assert_nil(params[:post], "Expected :post to be nil but got #{params[:post].inspect}")
end

Then('the BlushCommand object should be {string}') do |expected|
  action = @blush_captured_actions.last
  params = action.to_h
  assert_equal(expected, params[:object],
    "Expected :object to be '#{expected}' but got #{params[:object].inspect}")
end

Then('the BlushCommand post should be {string}') do |expected|
  action = @blush_captured_actions.last
  params = action.to_h
  assert_equal(expected, params[:post],
    "Expected :post to be '#{expected}' but got #{params[:post].inspect}")
end
