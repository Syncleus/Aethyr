# frozen_string_literal: true
###############################################################################
# Step definitions for AinfoCommand action coverage.                          #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/ainfo'
require 'aethyr/core/objects/info/info'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AinfoWorld
  attr_accessor :ainfo_player, :ainfo_object_ref, :ainfo_command, :ainfo_attrib,
                :ainfo_value, :ainfo_target, :ainfo_admin_calls,
                :ainfo_find_returns_nil
end
World(AinfoWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Minimal game-object double for the target of an ainfo command.
class AinfoTargetObject
  attr_accessor :name, :goid, :info

  def initialize(name = "test object")
    @name = name
    @goid = "ainfo_target_goid_123"
    @info = Info.new
  end

  def to_s
    @name
  end
end

# Recording player double that captures output messages.
class AinfoPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "ainfo_room_goid_1"
    @name      = "TestAdmin"
    @goid      = "ainfo_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AinfoCommand environment') do
  @ainfo_player          = AinfoPlayer.new
  @ainfo_object_ref      = nil
  @ainfo_command         = nil
  @ainfo_attrib          = nil
  @ainfo_value           = nil
  @ainfo_target          = nil
  @ainfo_admin_calls     = []
  @ainfo_find_returns_nil = false

  # Ensure `log` is available as a no-op (used in the "all" branch at line 22).
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Provide a room object for $manager.get_object(player.container)
  room_obj = AinfoTargetObject.new("Test Room")
  room_obj.goid = @ainfo_player.container

  # Build a stub manager that supports get_object, find, find_all
  mgr = Object.new

  player_ref        = @ainfo_player
  find_nil_flag     = -> { @ainfo_find_returns_nil }
  target_ref        = -> { @ainfo_target }
  admin_calls_ref   = @ainfo_admin_calls

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_obj
    elsif goid == target_ref.call&.goid
      target_ref.call
    else
      nil
    end
  end

  mgr.define_singleton_method(:find) do |name, *_args|
    return nil if find_nil_flag.call
    t = target_ref.call
    return t if t && (t.goid == name || t.name == name)
    nil
  end

  mgr.define_singleton_method(:find_all) do |_attrib, _klass|
    # Return two small stub objects so the each-loop executes
    obj1 = AinfoTargetObject.new("obj1")
    obj1.goid = "ainfo_obj1"
    obj2 = AinfoTargetObject.new("obj2")
    obj2.goid = "ainfo_obj2"
    [obj1, obj2]
  end

  mgr.define_singleton_method(:submit_action) { |_a| }

  $manager = mgr

  # Stub the Admin constant used at line 38.
  unless defined?(::Admin)
    admin_mod = Module.new
    Object.const_set(:Admin, admin_mod)
  end

  # Re-define Admin.ainfo each scenario so the closure captures the right array.
  ::Admin.define_singleton_method(:ainfo) do |event, _player, _room|
    admin_calls_ref << event
  end
end

Given('an ainfo target object exists') do
  @ainfo_target = AinfoTargetObject.new("shiny gem")
end

Given('an ainfo target object exists with info attribute {string} set to {string}') do |attr, val|
  @ainfo_target = AinfoTargetObject.new("shiny gem")
  @ainfo_target.info.set(attr, val)
end

Given('the ainfo object reference is the target goid') do
  @ainfo_object_ref = @ainfo_target.goid
end

Given('the ainfo object reference is {string}') do |ref|
  @ainfo_object_ref = ref
end

Given('the ainfo command is {string}') do |cmd|
  @ainfo_command = cmd
end

Given('the ainfo attrib is {string}') do |attr|
  @ainfo_attrib = attr
end

Given('the ainfo value is {string}') do |val|
  @ainfo_value = val
end

Given('ainfo find_object will return nil') do
  @ainfo_find_returns_nil = true
end

Given('an ainfo target object exists for {string}') do |keyword|
  @ainfo_target = AinfoTargetObject.new("Test Room")
  @ainfo_object_ref = keyword
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AinfoCommand action is invoked') do
  data = {
    object: @ainfo_object_ref,
  }
  data[:command] = @ainfo_command if @ainfo_command
  data[:attrib]  = @ainfo_attrib  if @ainfo_attrib
  data[:value]   = @ainfo_value   if @ainfo_value

  cmd = Aethyr::Core::Actions::Ainfo::AinfoCommand.new(@ainfo_player, **data)

  # Patch find_object on this instance so it returns our controlled target.
  target_ref        = -> { @ainfo_target }
  find_nil_flag     = -> { @ainfo_find_returns_nil }
  player_ref        = @ainfo_player

  cmd.define_singleton_method(:find_object) do |name, _event|
    return nil if find_nil_flag.call
    t = target_ref.call
    # For "here" the code replaces self[:object] with player.container (a goid string)
    # For "me" the code replaces self[:object] with the player object itself
    if t && (name == t.goid || name == t.name || name == player_ref.container || name == player_ref)
      t
    else
      nil
    end
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the ainfo player should see {string}') do |fragment|
  match = @ainfo_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected ainfo player output containing #{fragment.inspect}, got: #{@ainfo_player.messages.inspect}")
end

Then('Admin.ainfo should have been called') do
  assert(!@ainfo_admin_calls.empty?,
    "Expected Admin.ainfo to have been called at least once, but it was not.")
end
