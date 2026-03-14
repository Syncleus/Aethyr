# frozen_string_literal: true
###############################################################################
# Step definitions for StatusCommand action coverage (lines 14-16).           #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/actions/commands/status'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module StatusWorld
  attr_accessor :status_player
end
World(StatusWorld)

###############################################################################
# Lightweight player double                                                   #
###############################################################################

# Recording player double that captures output messages and provides
# health, satiety, and pose attributes needed by StatusCommand#action.
class StatusTestPlayer
  attr_accessor :container, :name, :goid
  attr_accessor :health_value, :satiety_value, :pose_value
  attr_reader   :messages

  def initialize
    @container     = "status_room_goid_1"
    @name          = "TestPlayer"
    @goid          = "status_player_goid_1"
    @messages      = []
    @health_value  = "in great shape"
    @satiety_value = "satisfied"
    @pose_value    = nil
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def health
    @health_value
  end

  def satiety
    @satiety_value
  end

  def pose
    @pose_value
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed StatusCommand environment') do
  @status_player = StatusTestPlayer.new

  # Ensure `log` is available as a no-op
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end
end

Given('the status player health is {string}') do |value|
  @status_player.health_value = value
end

Given('the status player satiety is {string}') do |value|
  @status_player.satiety_value = value
end

Given('the status player pose is {string}') do |value|
  @status_player.pose_value = value
end

Given('the status player pose is nil') do
  @status_player.pose_value = nil
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the StatusCommand action is invoked') do
  cmd = Aethyr::Core::Actions::Status::StatusCommand.new(@status_player)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the status player should see {string}') do |fragment|
  match = @status_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected status player output containing #{fragment.inspect}, got: #{@status_player.messages.inspect}")
end
