# frozen_string_literal: true
###############################################################################
# Step definitions for AteachCommand action coverage.                         #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/ateach'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module - scenario-scoped state                                        #
###############################################################################
module AteachWorld
  attr_accessor :ateach_player, :ateach_command, :ateach_room,
                :ateach_target_ref, :ateach_target_object,
                :ateach_find_object_nil, :ateach_alearn_called
end
World(AteachWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AteachPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "ateach_room_goid_1"
    @name      = "TestAdmin"
    @goid      = "ateach_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# Room double
class AteachRoom
  def name
    "Test Room"
  end

  def goid
    "ateach_room_goid_1"
  end
end

# Target object double
class AteachTargetObject
  attr_accessor :name, :goid

  def initialize(name = "student npc", goid = "target_goid_1")
    @name = name
    @goid = goid
  end

  def to_s
    @name
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################

Given('a stubbed AteachCommand environment') do
  @ateach_player           = AteachPlayer.new
  @ateach_room             = AteachRoom.new
  @ateach_target_ref       = nil
  @ateach_target_object    = nil
  @ateach_find_object_nil  = false
  @ateach_alearn_called    = false

  # Build a stub manager
  room_ref   = @ateach_room
  player_ref = @ateach_player

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref
    else
      nil
    end
  end

  mgr.define_singleton_method(:find) do |name, *_args|
    nil
  end

  $manager = mgr

  # Ensure `log` is available as a no-op
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end
end

Given('the ateach target is {string}') do |target|
  @ateach_target_ref = target
end

Given('ateach find_object returns nil') do
  @ateach_find_object_nil = true
end

Given('ateach find_object returns a valid object') do
  @ateach_find_object_nil = false
  @ateach_target_object = AteachTargetObject.new("student npc", "target_goid_1")
end

###############################################################################
# When steps                                                                  #
###############################################################################

When('the AteachCommand action is invoked') do
  data = {}
  data[:target] = @ateach_target_ref if @ateach_target_ref

  cmd = Aethyr::Core::Actions::Ateach::AteachCommand.new(@ateach_player, **data)

  # Patch find_object on this instance to return controlled values.
  ateach_world = self
  cmd.define_singleton_method(:find_object) do |_name, _event|
    return nil if ateach_world.ateach_find_object_nil
    ateach_world.ateach_target_object
  end

  # Patch alearn on this instance to record calls instead of executing.
  cmd.define_singleton_method(:alearn) do |_event, _object, _room|
    ateach_world.ateach_alearn_called = true
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################

Then('the ateach player should see {string}') do |fragment|
  match = @ateach_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected ateach player output containing #{fragment.inspect}, got: #{@ateach_player.messages.inspect}")
end

Then('ateach alearn should have been called') do
  assert(@ateach_alearn_called,
    "Expected alearn to have been called, but it was not.")
end
