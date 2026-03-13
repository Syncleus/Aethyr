# frozen_string_literal: true
###############################################################################
# Step definitions for DeletePlayerCommand action coverage.                   #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/actions/commands/delete_player'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module DelPlayerWorld
  attr_accessor :delplr_player, :delplr_room, :delplr_command,
                :delplr_existing_players, :delplr_logged_in_players,
                :delplr_delete_fails_for
end
World(DelPlayerWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class DelPlrMockPlayer
  attr_accessor :container, :name

  def initialize
    @container = "delplr_room_goid_1"
    @name      = "AdminPlayer"
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
class DelPlrMockRoom
  attr_accessor :name

  def initialize
    @name = "DelPlrTestRoom"
  end
end

# Mock manager that supports player_exist?, find, delete_player, get_object
class DelPlrMockManager
  attr_accessor :existing_players, :logged_in_players, :delete_fails_for

  def initialize(player, room)
    @player           = player
    @room             = room
    @existing_players = {}
    @logged_in_players = {}
    @delete_fails_for = {}
  end

  def get_object(goid)
    if goid == @player.container
      @room
    end
  end

  def player_exist?(name)
    @existing_players.fetch(name, false)
  end

  def find(name)
    @logged_in_players.fetch(name, nil)
  end

  def delete_player(name)
    unless @delete_fails_for[name]
      @existing_players.delete(name)
      @logged_in_players.delete(name)
    end
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed DeletePlayerCommand environment') do
  @delplr_player = DelPlrMockPlayer.new
  @delplr_room   = DelPlrMockRoom.new

  # Provide log method if not already available
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  mgr = DelPlrMockManager.new(@delplr_player, @delplr_room)
  @delplr_manager = mgr
  $manager = mgr
end

Given('the delplr manager reports player {string} does not exist') do |name|
  @delplr_manager.existing_players[name] = false
end

Given('the delplr manager reports player {string} exists') do |name|
  @delplr_manager.existing_players[name] = true
end

Given('the delplr manager reports player {string} is logged in') do |name|
  @delplr_manager.logged_in_players[name] = true
end

Given('the delplr manager reports player {string} is not logged in') do |name|
  @delplr_manager.logged_in_players[name] = nil
end

Given('the delplr manager will fail to fully delete {string}') do |name|
  @delplr_manager.delete_fails_for[name] = true
end

Given('the delplr manager will successfully delete {string}') do |name|
  @delplr_manager.delete_fails_for[name] = false
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the DeletePlayerCommand action is invoked for {string}') do |target_name|
  @delplr_command = Aethyr::Core::Actions::DeletePlayer::DeletePlayerCommand.new(
    @delplr_player,
    object: target_name
  )
  @delplr_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the delplr player should see {string}') do |fragment|
  match = @delplr_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected delplr player output containing #{fragment.inspect}, got: #{@delplr_player.messages.inspect}")
end
