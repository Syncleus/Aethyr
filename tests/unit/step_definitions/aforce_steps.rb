# frozen_string_literal: true
###############################################################################
# Step definitions for AforceCommand action coverage.                         #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/aforce'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AforceWorld
  attr_accessor :aforce_player, :aforce_target_ref, :aforce_target,
                :aforce_find_returns_nil
end
World(AforceWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AforcePlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "aforce_room_goid_1"
    @name      = "TestAdmin"
    @goid      = "aforce_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Minimal game-object double for a non-Player target.
class AforceTargetObject
  attr_accessor :name, :goid, :container

  def initialize(name = "test object", container = "aforce_room_goid_1")
    @name      = name
    @goid      = "aforce_target_goid_123"
    @container = container
  end

  def is_a?(klass)
    false
  end

  def to_s
    @name
  end
end

# A target that pretends to be a Player.
class AforcePlayerObject < AforceTargetObject
  def is_a?(klass)
    klass == Aethyr::Core::Objects::Player
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AforceCommand environment') do
  @aforce_player           = AforcePlayer.new
  @aforce_target_ref       = nil
  @aforce_target           = nil
  @aforce_find_returns_nil = false

  # Ensure `log` is available as a no-op.
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Provide a room object for $manager.get_object(player.container)
  room_obj = OpenStruct.new(name: "Test Room", goid: @aforce_player.container)

  # Build a stub manager
  mgr = Object.new

  player_ref    = @aforce_player
  find_nil_flag = -> { @aforce_find_returns_nil }
  target_ref    = -> { @aforce_target }

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_obj
    else
      nil
    end
  end

  mgr.define_singleton_method(:find) do |name, *_args|
    return nil if find_nil_flag.call
    target_ref.call
  end

  mgr.define_singleton_method(:submit_action) { |_a| }

  $manager = mgr
end

Given('the aforce target is {string}') do |ref|
  @aforce_target_ref = ref
end

Given('aforce find_object will return nil') do
  @aforce_find_returns_nil = true
end

Given('the aforce target object is a Player') do
  @aforce_target     = AforcePlayerObject.new("SomePlayer")
  @aforce_target_ref = @aforce_target.goid
end

Given('the aforce target object is a non-Player') do
  @aforce_target     = AforceTargetObject.new("wooden chair")
  @aforce_target_ref = @aforce_target.goid
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AforceCommand action is invoked') do
  data = { target: @aforce_target_ref }

  cmd = Aethyr::Core::Actions::Aforce::AforceCommand.new(@aforce_player, **data)

  # Patch find_object on this instance so it returns our controlled target.
  target_ref    = -> { @aforce_target }
  find_nil_flag = -> { @aforce_find_returns_nil }

  cmd.define_singleton_method(:find_object) do |_name, _event|
    return nil if find_nil_flag.call
    target_ref.call
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the aforce player should see {string}') do |fragment|
  match = @aforce_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected aforce player output containing #{fragment.inspect}, got: #{@aforce_player.messages.inspect}")
end
