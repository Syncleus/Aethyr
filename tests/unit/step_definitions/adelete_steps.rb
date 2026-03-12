# frozen_string_literal: true
###############################################################################
# Step definitions for AdeleteCommand action coverage.                        #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/adelete'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AdeleteWorld
  attr_accessor :adelete_player, :adelete_object_ref, :adelete_target,
                :adelete_find_returns_nil, :adelete_admin_calls,
                :adelete_room_events, :adelete_cmd
end
World(AdeleteWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AdeletePlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "room_goid_1"
    @name      = "TestAdmin"
    @goid      = "player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def pronoun(type = :normal)
    case type
    when :possessive then "his"
    else "he"
    end
  end
end

# Minimal game-object double for the target of an adelete command.
class AdeleteTargetObject
  attr_accessor :name, :goid, :container

  def initialize(name = "test object", container = "room_goid_1")
    @name      = name
    @goid      = "target_goid_123"
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
class AdeletePlayerObject < AdeleteTargetObject
  def is_a?(klass)
    klass == Aethyr::Core::Objects::Player
  end
end

# Room double that records out_event calls.
class AdeleteRoom
  attr_accessor :goid
  attr_reader :events

  def initialize(goid = "room_goid_1")
    @goid   = goid
    @events = []
  end

  def out_event(event)
    @events << event
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AdeleteCommand environment') do
  @adelete_player          = AdeletePlayer.new
  @adelete_object_ref      = nil
  @adelete_target          = nil
  @adelete_find_returns_nil = false
  @adelete_admin_calls     = []
  @adelete_room_events     = []
  @adelete_room            = AdeleteRoom.new("room_goid_1")

  # Ensure `log` is available as a no-op (the production code calls `log`).
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager
  mgr = Object.new

  player_ref      = @adelete_player
  find_nil_flag   = -> { @adelete_find_returns_nil }
  target_ref      = -> { @adelete_target }
  room_ref        = -> { @adelete_room }

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref.call
    else
      nil
    end
  end

  mgr.define_singleton_method(:find) do |name, *_args|
    return nil if find_nil_flag.call
    target_ref.call
  end

  mgr.define_singleton_method(:find_all) do |_attrib, _klass|
    obj1 = OpenStruct.new(goid: "obj1")
    obj2 = OpenStruct.new(goid: "obj2")
    [obj1, obj2]
  end

  mgr.define_singleton_method(:delete_object) do |_obj|
    # no-op
  end

  mgr.define_singleton_method(:submit_action) { |_a| }

  $manager = mgr

  # Stub the Admin constant.
  admin_calls_ref = @adelete_admin_calls
  unless defined?(::Admin)
    admin_mod = Module.new
    Object.const_set(:Admin, admin_mod)
  end

  ::Admin.define_singleton_method(:adelete) do |event, _player, _room|
    admin_calls_ref << event
  end
end

Given('the adelete object reference is {string}') do |ref|
  @adelete_object_ref = ref
end

Given('adelete find_object will return nil') do
  @adelete_find_returns_nil = true
end

Given('the adelete object is a Player') do
  @adelete_target     = AdeletePlayerObject.new("SomePlayer", "room_goid_1")
  @adelete_object_ref = @adelete_target.goid
end

Given('the adelete object is in the same room') do
  @adelete_target     = AdeleteTargetObject.new("shiny gem", "room_goid_1")
  @adelete_object_ref = @adelete_target.goid
end

Given('the adelete object is in a different room') do
  @adelete_target     = AdeleteTargetObject.new("distant gem", "other_room_goid")
  @adelete_object_ref = @adelete_target.goid
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AdeleteCommand action is invoked') do
  data = { object: @adelete_object_ref }

  cmd = Aethyr::Core::Actions::Adelete::AdeleteCommand.new(@adelete_player, **data)
  @adelete_cmd = cmd

  # Patch find_object on this instance so it returns our controlled target.
  target_ref    = -> { @adelete_target }
  find_nil_flag = -> { @adelete_find_returns_nil }

  cmd.define_singleton_method(:find_object) do |_name, _event|
    return nil if find_nil_flag.call
    target_ref.call
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the AdeleteCommand should be instantiated successfully') do
  cmd = Aethyr::Core::Actions::Adelete::AdeleteCommand.new(@adelete_player, object: "test")
  assert_not_nil(cmd, "Expected AdeleteCommand to be instantiated")
end

Then('the adelete player should see {string}') do |fragment|
  match = @adelete_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@adelete_player.messages.inspect}")
end

Then('Admin.adelete should have been called for adelete') do
  assert(!@adelete_admin_calls.empty?,
    "Expected Admin.adelete to have been called at least once, but it was not.")
end

Then('the adelete room should receive the event') do
  assert(!@adelete_room.events.empty?,
    "Expected room to receive an out_event call, but it did not. Room events: #{@adelete_room.events.inspect}")
end
