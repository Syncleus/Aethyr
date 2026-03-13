# frozen_string_literal: true
###############################################################################
# Step definitions for GaitCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/gait'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module GaitCommandWorld
  attr_accessor :gait_player, :gait_room
end
World(GaitCommandWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Info bag backed by OpenStruct for dynamic attribute access.
class GaitInfoBag < OpenStruct; end

# Recording player double that captures output and supports info / exit_message.
class GaitCommandPlayer
  attr_accessor :container, :name, :goid, :info

  def initialize
    @container = "gait_room_goid_1"
    @name      = "TestWalker"
    @goid      = "gait_player_goid_1"
    @messages  = []
    @info      = GaitInfoBag.new(entrance_message: nil, exit_message: nil)
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def messages
    @messages
  end

  # Mirrors GameObject#exit_message – formats exit_message template or
  # returns a generic message, just like the production code.
  def exit_message(direction, message = nil)
    if @info.exit_message && !message
      message = @info.exit_message
    end

    case direction
    when "up"    then direction = "go up"
    when "down"  then direction = "go down"
    when "in"    then direction = "go inside"
    when "out"   then direction = "go outside"
    else              direction = "the " + direction
    end

    if message
      message.gsub(/!direction/, direction).gsub(/!name/, @name)
    else
      "#{@name.capitalize} leaves to #{direction}."
    end
  end
end

# Minimal room double.
class GaitCommandRoom
  attr_accessor :goid

  def initialize
    @goid = "gait_room_goid_1"
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed GaitCommand environment') do
  @gait_player = GaitCommandPlayer.new
  @gait_room   = GaitCommandRoom.new

  room_ref = @gait_room

  mgr = Object.new
  mgr.define_singleton_method(:get_object) do |goid|
    goid == room_ref.goid ? room_ref : nil
  end

  $manager = mgr
end

Given('the gait player has no entrance message') do
  @gait_player.info.entrance_message = nil
end

Given('the gait player has entrance message {string}') do |msg|
  @gait_player.info.entrance_message = "#{msg}, !name comes in from !direction."
  @gait_player.info.exit_message     = "#{msg}, !name leaves to !direction."
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the GaitCommand action is invoked with no phrase') do
  cmd = Aethyr::Core::Actions::Gait::GaitCommand.new(@gait_player)
  cmd.action
end

When('the GaitCommand action is invoked with phrase {string}') do |phrase|
  cmd = Aethyr::Core::Actions::Gait::GaitCommand.new(@gait_player, phrase: phrase)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the gait player should see {string}') do |fragment|
  match = @gait_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@gait_player.messages.inspect}")
end

Then('the gait player entrance message should be nil') do
  assert_nil(@gait_player.info.entrance_message,
    "Expected entrance_message to be nil, got: #{@gait_player.info.entrance_message.inspect}")
end

Then('the gait player exit message should be nil') do
  assert_nil(@gait_player.info.exit_message,
    "Expected exit_message to be nil, got: #{@gait_player.info.exit_message.inspect}")
end

Then('the gait player entrance message should be {string}') do |expected|
  assert_equal(expected, @gait_player.info.entrance_message,
    "Expected entrance_message to be #{expected.inspect}, got: #{@gait_player.info.entrance_message.inspect}")
end

Then('the gait player exit message should be {string}') do |expected|
  assert_equal(expected, @gait_player.info.exit_message,
    "Expected exit_message to be #{expected.inspect}, got: #{@gait_player.info.exit_message.inspect}")
end
