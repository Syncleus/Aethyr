# frozen_string_literal: true
###############################################################################
# Step definitions for AwatchCommand action coverage.                         #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/awatch'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AwatchWorld
  attr_accessor :awatch_player, :awatch_command, :awatch_target_key,
                :awatch_mobile, :awatch_non_mobile
end
World(AwatchWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Define a top-level Mobile class for is_a? checks unless already present.
unless defined?(::Mobile)
  class ::Mobile; end
end

# Recording player double that captures output messages.
class AwatchPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "awatch_room_goid_1"
    @name      = "TestWatcher"
    @goid      = "awatch_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Mobile double that records output and tracks info.redirect_output_to.
class AwatchMobile < ::Mobile
  attr_accessor :name
  attr_reader :messages, :info

  def initialize(name)
    @name     = name
    @messages = []
    @info     = OpenStruct.new(redirect_output_to: nil)
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Non-mobile object double (fails the is_a?(Mobile) check).
class AwatchNonMobile
  attr_accessor :name

  def initialize(name = "Rock")
    @name = name
  end

  def output(msg, *_args); end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AwatchCommand environment') do
  @awatch_player     = AwatchPlayer.new
  @awatch_command    = nil
  @awatch_target_key = nil
  @awatch_mobile     = nil
  @awatch_non_mobile = nil

  # Provide a room object for $manager.get_object(player.container)
  room_obj = OpenStruct.new(name: "Test Room", goid: "awatch_room_goid_1")

  # Build a stub manager; lookup table is filled per-scenario
  mgr = Object.new
  player_ref  = @awatch_player
  world_ref   = self  # reference to Cucumber World for accessing instance vars

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_obj
    else
      nil
    end
  end

  mgr.define_singleton_method(:find) do |name, _scope|
    return nil if name.nil?
    mob = world_ref.instance_variable_get(:@awatch_mobile)
    non_mob = world_ref.instance_variable_get(:@awatch_non_mobile)
    if mob && name == mob.name
      mob
    elsif non_mob && name == non_mob.name
      non_mob
    else
      nil
    end
  end

  $manager = mgr
end

Given('the awatch target is nil') do
  @awatch_target_key = nil
end

Given('the awatch target is a non-mobile object') do
  @awatch_non_mobile = AwatchNonMobile.new("Rock")
  @awatch_target_key = "Rock"
end

Given('the awatch target is a mobile named {string}') do |name|
  @awatch_mobile     = AwatchMobile.new(name)
  @awatch_target_key = name
end

Given('the awatch mobile is already redirecting to the player') do
  @awatch_mobile.info.redirect_output_to = @awatch_player.goid
end

Given('the awatch mobile is not redirecting to the player') do
  @awatch_mobile.info.redirect_output_to = nil
end

Given('the awatch command is {string}') do |cmd|
  @awatch_command = cmd
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AwatchCommand action is invoked') do
  data = {}
  data[:target]  = @awatch_target_key if @awatch_target_key
  data[:command]  = @awatch_command    if @awatch_command

  cmd = Aethyr::Core::Actions::Awatch::AwatchCommand.new(@awatch_player, **data)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the awatch player should see {string}') do |fragment|
  match = @awatch_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected awatch player output containing #{fragment.inspect}, " \
    "got: #{@awatch_player.messages.inspect}")
end

Then('the awatch mobile should see {string}') do |fragment|
  match = @awatch_mobile.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected awatch mobile output containing #{fragment.inspect}, " \
    "got: #{@awatch_mobile.messages.inspect}")
end

Then('the awatch mobile redirect should be set to the player') do
  assert_equal(@awatch_player.goid, @awatch_mobile.info.redirect_output_to,
    "Expected mobile redirect_output_to to be #{@awatch_player.goid.inspect}, " \
    "got #{@awatch_mobile.info.redirect_output_to.inspect}")
end

Then('the awatch mobile redirect should be nil') do
  assert_nil(@awatch_mobile.info.redirect_output_to,
    "Expected mobile redirect_output_to to be nil, " \
    "got #{@awatch_mobile.info.redirect_output_to.inspect}")
end
