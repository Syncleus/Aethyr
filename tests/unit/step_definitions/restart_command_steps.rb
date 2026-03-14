# frozen_string_literal: true
###############################################################################
# Step definitions for RestartCommand action coverage.                        #
#                                                                             #
# Covers lines 15-17 of lib/aethyr/core/actions/commands/restart.rb:         #
#   15: room = $manager.get_object(@player.container)                         #
#   16: player = @player                                                      #
#   17: $manager.restart                                                      #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/actions/commands/restart'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module RestartCommandWorld
  attr_accessor :restart_player, :restart_room, :restart_command,
                :restart_manager_restart_called, :restart_manager_get_object_called
end
World(RestartCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class RestartMockPlayer
  attr_accessor :container, :name

  def initialize
    @container = "restart_room_goid_1"
    @name      = "RestartTestAdmin"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def messages
    @messages
  end
end

# Mock room returned by $manager.get_object
class RestartMockRoom
  attr_accessor :name

  def initialize
    @name = "RestartTestRoom"
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed RestartCommand environment') do
  @restart_player = RestartMockPlayer.new
  @restart_room   = RestartMockRoom.new
  @restart_manager_restart_called    = false
  @restart_manager_get_object_called = false

  # Ensure `log` is available as a no-op
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager
  player_ref = @restart_player
  room_ref   = @restart_room
  world_ref  = self

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      world_ref.restart_manager_get_object_called = true
      room_ref
    end
  end

  mgr.define_singleton_method(:restart) do
    world_ref.restart_manager_restart_called = true
  end

  $manager = mgr
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the RestartCommand action is invoked') do
  @restart_command = Aethyr::Core::Actions::Restart::RestartCommand.new(@restart_player)
  @restart_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the restart manager should have resolved the room') do
  assert(@restart_manager_get_object_called,
    "Expected $manager.get_object to have been called with the player's container, but it was not.")
end

Then('the restart manager restart should have been called') do
  assert(@restart_manager_restart_called,
    "Expected $manager.restart to have been called, but it was not.")
end
