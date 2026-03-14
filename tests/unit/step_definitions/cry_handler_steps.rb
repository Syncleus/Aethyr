# frozen_string_literal: true
################################################################################
# Step definitions for validating CryHandler input parsing.                    #
#                                                                              #
# These steps exercise the `player_input` method on CryHandler, ensuring the   #
# regex parsing correctly extracts `object` and `post` parameters and submits  #
# a CryCommand to the manager.                                                 #
################################################################################

require 'test/unit/assertions'
require 'aethyr/core/input_handlers/emotes/cry'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# Shared state for CryHandler scenarios                                       #
###############################################################################
module CryHandlerWorld
  attr_accessor :cry_player, :cry_handler, :cry_captured_actions
end
World(CryHandlerWorld)

###############################################################################
# Stub manager that records submitted actions                                 #
###############################################################################
class CryHandlerStubManager
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
Given('a stubbed CryHandler environment') do
  @cry_player  = ::Aethyr::Core::Objects::MockPlayer.new('CryTestPlayer')
  @cry_handler = Aethyr::Core::Commands::Cry::CryHandler.new(@cry_player)

  $manager = CryHandlerStubManager.new
  @cry_captured_actions = $manager.actions
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the cry player enters {string}') do |input|
  @cry_captured_actions.clear
  @cry_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the cry manager should receive a CryCommand') do
  assert(!@cry_captured_actions.empty?,
    'No actions were captured – submit_action was not invoked')
  assert_instance_of(
    Aethyr::Core::Actions::Cry::CryCommand,
    @cry_captured_actions.last,
    "Expected a CryCommand but received #{@cry_captured_actions.last.class}"
  )
end

Then('the cry manager should not receive any action') do
  assert(@cry_captured_actions.empty?,
    "Expected no actions but got: #{@cry_captured_actions.inspect}")
end

Then('the CryCommand object should be nil') do
  cmd = @cry_captured_actions.last
  params = cmd.to_h
  assert_nil(params[:object], "Expected :object to be nil but got #{params[:object].inspect}")
end

Then('the CryCommand object should be {string}') do |expected|
  cmd = @cry_captured_actions.last
  params = cmd.to_h
  assert_equal(expected, params[:object],
    "Expected :object to be '#{expected}' but got #{params[:object].inspect}")
end

Then('the CryCommand post should be nil') do
  cmd = @cry_captured_actions.last
  params = cmd.to_h
  assert_nil(params[:post], "Expected :post to be nil but got #{params[:post].inspect}")
end

Then('the CryCommand post should be {string}') do |expected|
  cmd = @cry_captured_actions.last
  params = cmd.to_h
  assert_equal(expected, params[:post],
    "Expected :post to be '#{expected}' but got #{params[:post].inspect}")
end
