# frozen_string_literal: true
################################################################################
# Step-definitions validating Aethyr::Core::Actions::Reply::ReplyCommand.      #
#                                                                              #
#   • SRP  – Each step performs exactly one behavioural assertion.              #
#   • OCP  – Production code remains untouched; seams are light-weight doubles.#
#   • LSP  – Test doubles honour the contracts expected by ReplyCommand.       #
#   • ISP  – Doubles implement *only* the interface actually exercised.        #
#   • DIP  – The concrete $manager global is replaced by a stub that conforms  #
#            to the abstract dependency.                                        #
################################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/reply'

World(Test::Unit::Assertions)

###############################################################################
# Shared state for reply scenarios                                             #
###############################################################################
module ReplyCommandWorld
  attr_accessor :reply_player, :reply_command, :reply_player_messages,
                :reply_action_tell_called, :reply_action_tell_arg
end
World(ReplyCommandWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# A minimal player stub with just the interface used by ReplyCommand.
class ReplyTestPlayer
  attr_accessor :name, :reply_to

  def initialize(name = 'ReplyTestPlayer')
    @name     = name
    @reply_to = nil
    @messages = []
  end

  def output(msg, *_args)
    @messages << msg
  end

  def messages
    @messages
  end
end

# A minimal manager stub (ReplyCommand does not use $manager directly,
# but it may be referenced during require chain initialisation).
class ReplyTestManager
  def get_object(_id)
    nil
  end
end

###############################################################################
# Given                                                                        #
###############################################################################

Given('a stubbed ReplyCommand environment') do
  @reply_player   = ReplyTestPlayer.new('ReplyTestPlayer')
  $manager        = ReplyTestManager.new
  @reply_player_messages    = @reply_player.messages
  @reply_action_tell_called = false
  @reply_action_tell_arg    = nil
end

Given('the reply player has no reply_to set') do
  @reply_player.reply_to = nil
end

Given('the reply player has reply_to set to {string}') do |target_name|
  @reply_player.reply_to = target_name
end

###############################################################################
# When                                                                         #
###############################################################################

When('the reply player performs the reply action') do
  @reply_command = Aethyr::Core::Actions::Reply::ReplyCommand.new(@reply_player)

  # Stub action_tell on this specific instance to record the call
  # without requiring the full runtime handler infrastructure.
  world = self
  @reply_command.define_singleton_method(:action_tell) do |event|
    world.reply_action_tell_called = true
    world.reply_action_tell_arg    = event
  end

  @reply_command.action
end

###############################################################################
# Then                                                                         #
###############################################################################

Then('the reply player should see {string}') do |expected|
  assert(@reply_player_messages.any? { |m| m.include?(expected) },
         "Expected player output to contain '#{expected}' but got: #{@reply_player_messages.inspect}")
end

Then('the reply command target should be {string}') do |expected|
  actual = @reply_command[:target]
  assert_equal(expected, actual,
               "Expected command target to be '#{expected}' but got: #{actual.inspect}")
end

Then('action_tell should have been called with the reply command') do
  assert(@reply_action_tell_called,
         'Expected action_tell to have been called but it was not')
  assert_equal(@reply_command, @reply_action_tell_arg,
               'Expected action_tell to be called with the command itself')
end
