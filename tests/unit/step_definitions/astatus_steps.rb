# frozen_string_literal: true
###############################################################################
# Step definitions for AstatusCommand action coverage.                        #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/astatus'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AstatusWorld
  attr_accessor :astatus_player, :astatus_type_counts, :astatus_total_objects,
                :astatus_awho_calls
end
World(AstatusWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AstatusPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "astatus_room_goid_1"
    @name      = "TestAdmin"
    @goid      = "astatus_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AstatusCommand environment') do
  @astatus_player        = AstatusPlayer.new
  @astatus_type_counts   = {}
  @astatus_total_objects  = 0
  @astatus_awho_calls    = []

  # Ensure `log` is available as a no-op
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Provide a room object for $manager.get_object(player.container)
  room_obj = OpenStruct.new(name: "Test Room", goid: @astatus_player.container)

  # Build a stub manager
  player_ref    = @astatus_player
  astatus_world = self

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_obj
    else
      nil
    end
  end

  mgr.define_singleton_method(:game_objects_count) do
    astatus_world.astatus_total_objects
  end

  mgr.define_singleton_method(:type_count) do
    astatus_world.astatus_type_counts
  end

  mgr.define_singleton_method(:submit_action) { |_a| }

  $manager = mgr
end

Given('the astatus manager has object types') do |table|
  @astatus_type_counts = {}
  table.hashes.each do |row|
    @astatus_type_counts[row['type']] = row['count'].to_i
  end
end

Given('the astatus manager has no object types') do
  @astatus_type_counts = {}
end

Given('the astatus manager game_objects_count is {int}') do |count|
  @astatus_total_objects = count
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AstatusCommand action is invoked') do
  cmd = Aethyr::Core::Actions::Astatus::AstatusCommand.new(@astatus_player)

  # Stub the awho method on this command instance so line 17 executes
  # without requiring the full admin subsystem.
  awho_calls = @astatus_awho_calls
  cmd.define_singleton_method(:awho) do |*args|
    awho_calls << args
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the astatus player should see {string}') do |fragment|
  match = @astatus_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected astatus player output containing #{fragment.inspect}, got: #{@astatus_player.messages.inspect}")
end

Then('the astatus awho should have been called') do
  assert(!@astatus_awho_calls.empty?,
    "Expected awho to have been called at least once, but it was not.")
end
