# frozen_string_literal: true
###############################################################################
# Step definitions for PoseCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/pose'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module PoseCommandWorld
  attr_accessor :pose_player, :pose_room
end
World(PoseCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output and supports pose attribute.
class PoseCommandPlayer
  attr_accessor :container, :name, :goid, :pose

  def initialize
    @container = "pose_room_goid_1"
    @name      = "TestPlayer"
    @goid      = "pose_player_goid_1"
    @messages  = []
    @pose      = nil
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def messages
    @messages
  end
end

# Minimal room double.
class PoseCommandRoom
  attr_accessor :goid

  def initialize
    @goid = "pose_room_goid_1"
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed PoseCommand environment') do
  @pose_player = PoseCommandPlayer.new
  @pose_room   = PoseCommandRoom.new

  room_ref = @pose_room

  mgr = Object.new
  mgr.define_singleton_method(:get_object) do |goid|
    goid == room_ref.goid ? room_ref : nil
  end

  $manager = mgr
end

Given('the pose player has pose {string}') do |pose_value|
  @pose_player.pose = pose_value
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the PoseCommand action is invoked with pose {string}') do |pose_value|
  cmd = Aethyr::Core::Actions::Pose::PoseCommand.new(@pose_player, pose: pose_value)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the pose player should see {string}') do |fragment|
  match = @pose_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@pose_player.messages.inspect}")
end

Then('the pose player pose should be nil') do
  assert_nil(@pose_player.pose,
    "Expected pose to be nil, got: #{@pose_player.pose.inspect}")
end

Then('the pose player pose should be {string}') do |expected|
  assert_equal(expected, @pose_player.pose,
    "Expected pose to be #{expected.inspect}, got: #{@pose_player.pose.inspect}")
end
