# frozen_string_literal: true
################################################################################
# Step-definitions validating Aethyr::Core::Actions::Tell::TellCommand.        #
#                                                                              #
#   • SRP  – Each step performs exactly one behavioural assertion.              #
#   • OCP  – Production code remains untouched; seams are light-weight doubles.#
#   • LSP  – Test doubles honour the contracts expected by TellCommand.        #
#   • ISP  – Doubles implement *only* the interface actually exercised.        #
#   • DIP  – The concrete $manager global is replaced by a stub that conforms  #
#            to the abstract «find» dependency.                                 #
################################################################################

require 'test/unit/assertions'
require 'aethyr/core/actions/commands/tell'

# Define the Aethyr::Core::Objects::Player constant as a stub so that
# tell.rb's `target.is_a? Aethyr::Core::Objects::Player` check can
# resolve the constant without loading the entire Player class tree.
module Aethyr
  module Core
    module Objects
      class Player; end unless defined?(Player)
    end
  end
end

World(Test::Unit::Assertions)

###############################################################################
# Shared state for tell scenarios                                              #
###############################################################################
module TellCommandWorld
  attr_accessor :tell_cmd_player, :tell_cmd_target, :tell_cmd_command,
                :tell_cmd_player_messages, :tell_cmd_target_messages
end
World(TellCommandWorld)

###############################################################################
# Lightweight doubles                                                          #
###############################################################################

# A minimal player stub with just the interface used by TellCommand.
class TellCmdMockPlayer
  attr_accessor :name, :messages

  def initialize(name = 'TestTeller')
    @name     = name
    @messages = []
  end

  def output(msg, *_args)
    @messages << msg
  end

  # Override is_a? so the self-tell check (target == @player) works via
  # object identity, but this object also passes the Player type-check
  # if it is ever used as a target (e.g. self-tell scenario).
  def is_a?(klass)
    return true if klass == Aethyr::Core::Objects::Player
    super
  end
end

# A mock target that passes the `target.is_a? Aethyr::Core::Objects::Player`
# check by overriding is_a?.
class TellCmdMockTarget
  attr_accessor :name, :reply_to, :messages

  def initialize(name = 'Bob')
    @name     = name
    @reply_to = nil
    @messages = []
  end

  def output(msg, *_args)
    @messages << msg
  end

  def is_a?(klass)
    return true if klass == Aethyr::Core::Objects::Player
    super
  end
end

# A mock non-player target that fails the Player type-check.
class TellCmdMockNonPlayer
  attr_accessor :name, :messages

  def initialize(name = 'npc_bob')
    @name     = name
    @messages = []
  end

  def output(msg, *_args)
    @messages << msg
  end

  # Deliberately does NOT override is_a? — will fail the Player check.
end

# A minimal manager stub whose find method looks up objects by identifier.
class TellCmdMockManager
  def initialize
    @registry = {}
  end

  def register(identifier, obj)
    @registry[identifier] = obj
  end

  def find(identifier)
    @registry[identifier]
  end
end

###############################################################################
# Given                                                                        #
###############################################################################
Given('a stubbed TellCommand environment') do
  @tell_cmd_player = TellCmdMockPlayer.new('TestTeller')
  @tell_cmd_target = TellCmdMockTarget.new('Bob')

  manager = TellCmdMockManager.new
  manager.register('Bob', @tell_cmd_target)
  # Register a non-player object for the non-player scenario
  manager.register('npc_bob', TellCmdMockNonPlayer.new('npc_bob'))
  $manager = manager

  @tell_cmd_player_messages = @tell_cmd_player.messages
  @tell_cmd_target_messages = @tell_cmd_target.messages
end

###############################################################################
# When                                                                         #
###############################################################################

When('the tell player sends {string} to an unknown target {string}') do |message, target_name|
  @tell_cmd_command = Aethyr::Core::Actions::Tell::TellCommand.new(
    @tell_cmd_player, target: target_name, message: message
  )
  @tell_cmd_command.action
end

When('the tell player sends {string} to a non-player target {string}') do |message, target_name|
  @tell_cmd_command = Aethyr::Core::Actions::Tell::TellCommand.new(
    @tell_cmd_player, target: target_name, message: message
  )
  @tell_cmd_command.action
end

When('the tell player sends {string} targeting themselves') do |message|
  # Register the player itself in the manager so find returns the player object
  $manager.register('me', @tell_cmd_player)
  @tell_cmd_command = Aethyr::Core::Actions::Tell::TellCommand.new(
    @tell_cmd_player, target: 'me', message: message
  )
  @tell_cmd_command.action
end

When('the tell player sends {string} to target {string}') do |message, target_name|
  @tell_cmd_command = Aethyr::Core::Actions::Tell::TellCommand.new(
    @tell_cmd_player, target: target_name, message: message
  )
  @tell_cmd_command.action
end

###############################################################################
# Then                                                                         #
###############################################################################

Then('the tell player should see {string}') do |expected|
  assert(@tell_cmd_player_messages.any? { |m| m.include?(expected) },
         "Expected player output to contain '#{expected}' but got: #{@tell_cmd_player_messages.inspect}")
end

Then('the tell player output should contain {string}') do |expected|
  assert(@tell_cmd_player_messages.any? { |m| m.include?(expected) },
         "Expected player output to contain '#{expected}' but got: #{@tell_cmd_player_messages.inspect}")
end

Then('the tell player output should not contain {string}') do |expected|
  assert(@tell_cmd_player_messages.none? { |m| m.include?(expected) },
         "Expected player output NOT to contain '#{expected}' but got: #{@tell_cmd_player_messages.inspect}")
end

Then('the tell target output should contain {string}') do |expected|
  assert(@tell_cmd_target_messages.any? { |m| m.include?(expected) },
         "Expected target output to contain '#{expected}' but got: #{@tell_cmd_target_messages.inspect}")
end

Then('the tell target output should not contain {string}') do |expected|
  assert(@tell_cmd_target_messages.none? { |m| m.include?(expected) },
         "Expected target output NOT to contain '#{expected}' but got: #{@tell_cmd_target_messages.inspect}")
end

Then('the tell target reply_to should be {string}') do |expected|
  assert_equal(expected, @tell_cmd_target.reply_to,
               "Expected target reply_to to be '#{expected}' but got: #{@tell_cmd_target.reply_to.inspect}")
end

Then('the tell target should have received no messages') do
  assert(@tell_cmd_target_messages.empty?,
         "Expected target to have received no messages but got: #{@tell_cmd_target_messages.inspect}")
end
