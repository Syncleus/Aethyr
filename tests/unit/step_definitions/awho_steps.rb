# frozen_string_literal: true
###############################################################################
# Step definitions for AwhoCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/awho'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AwhoWorld
  attr_accessor :awho_player, :awho_room, :awho_command,
                :awho_find_all_result
end
World(AwhoWorld)

###############################################################################
# Ensure the bare Player constant exists for awho.rb line 17                  #
###############################################################################
unless defined?(Player)
  Player = Class.new do
    attr_accessor :name
    def initialize(name = "DefaultPlayer")
      @name = name
    end
  end
end

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AwhoMockPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "awho_room_goid_1"
    @name      = "AwhoTestPlayer"
    @goid      = "awho_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Simple mock room
class AwhoMockRoom
  attr_accessor :name

  def initialize
    @name = "AwhoTestRoom"
  end
end

# Simple mock online player returned by find_all
class AwhoMockOnlinePlayer
  attr_accessor :name

  def initialize(name)
    @name = name
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AwhoCommand environment') do
  @awho_player          = AwhoMockPlayer.new
  @awho_room            = AwhoMockRoom.new
  @awho_find_all_result = []

  # Ensure `log` is available as a no-op
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager
  player_ref = @awho_player
  room_ref   = @awho_room
  awho_world = self

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref
    else
      nil
    end
  end

  mgr.define_singleton_method(:find_all) do |_attrib, _query|
    awho_world.awho_find_all_result
  end

  $manager = mgr
end

Given('the awho manager find_all returns one player named {string}') do |name|
  @awho_find_all_result = [AwhoMockOnlinePlayer.new(name)]
end

Given('the awho manager find_all returns players named {string}') do |names_csv|
  @awho_find_all_result = names_csv.split(',').map do |n|
    AwhoMockOnlinePlayer.new(n.strip)
  end
end

Given('the awho manager find_all returns no players') do
  @awho_find_all_result = []
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AwhoCommand action is invoked') do
  @awho_command = Aethyr::Core::Actions::Awho::AwhoCommand.new(@awho_player)
  @awho_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the awho player should see {string}') do |fragment|
  match = @awho_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected awho player output containing #{fragment.inspect}, got: #{@awho_player.messages.inspect}")
end
