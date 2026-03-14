# frozen_string_literal: true
################################################################################
# Step definitions for validating EhHandler input parsing.                     #
#                                                                              #
# These steps exercise the `player_input` method on EhHandler, ensuring the    #
# regex parsing correctly extracts `object` and `post` parameters and submits  #
# an EhCommand to the manager.                                                 #
################################################################################

require 'test/unit/assertions'
require 'aethyr/core/input_handlers/emotes/eh'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# Shared state for EhHandler scenarios                                        #
###############################################################################
module EhHandlerWorld
  attr_accessor :eh_player, :eh_handler, :eh_captured_actions
end
World(EhHandlerWorld)

###############################################################################
# Stub manager that records submitted actions                                 #
###############################################################################
class EhHandlerStubManager
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
Given('a stubbed EhHandler environment') do
  @eh_player  = ::Aethyr::Core::Objects::MockPlayer.new('EhTestPlayer')
  @eh_handler = Aethyr::Core::Commands::Eh::EhHandler.new(@eh_player)

  $manager = EhHandlerStubManager.new
  @eh_captured_actions = $manager.actions
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the eh player enters {string}') do |input|
  @eh_captured_actions.clear
  @eh_handler.player_input(input: input)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the eh manager should receive an EhCommand') do
  assert(!@eh_captured_actions.empty?,
    'No actions were captured – submit_action was not invoked')
  assert_instance_of(
    Aethyr::Core::Actions::Eh::EhCommand,
    @eh_captured_actions.last,
    "Expected an EhCommand but received #{@eh_captured_actions.last.class}"
  )
end

Then('the eh manager should not receive any action') do
  assert(@eh_captured_actions.empty?,
    "Expected no actions but got: #{@eh_captured_actions.inspect}")
end

Then('the EhCommand object should be nil') do
  cmd = @eh_captured_actions.last
  params = cmd.to_h
  assert_nil(params[:object], "Expected :object to be nil but got #{params[:object].inspect}")
end

Then('the EhCommand object should be {string}') do |expected|
  cmd = @eh_captured_actions.last
  params = cmd.to_h
  assert_equal(expected, params[:object],
    "Expected :object to be '#{expected}' but got #{params[:object].inspect}")
end

Then('the EhCommand post should be nil') do
  cmd = @eh_captured_actions.last
  params = cmd.to_h
  assert_nil(params[:post], "Expected :post to be nil but got #{params[:post].inspect}")
end

Then('the EhCommand post should be {string}') do |expected|
  cmd = @eh_captured_actions.last
  params = cmd.to_h
  assert_equal(expected, params[:post],
    "Expected :post to be '#{expected}' but got #{params[:post].inspect}")
end
