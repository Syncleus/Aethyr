# frozen_string_literal: true
###############################################################################
# Step definitions for AsetCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/aset'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AsetWorld
  attr_accessor :aset_player, :aset_object_ref, :aset_attribute, :aset_value,
                :aset_target, :aset_force, :aset_admin_calls,
                :aset_find_returns_nil
end
World(AsetWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Info bag that supports dynamic attribute storage (smell, texture, etc.)
class AsetInfoBag < OpenStruct
  def delete(key)
    @table.delete(key)
  end
end

# Minimal game-object double for the target of an aset command.
class AsetTargetObject
  attr_accessor :name, :goid, :info

  def initialize(name = "test object")
    @name = name
    @goid = "target_goid_123"
    @info = AsetInfoBag.new
  end

  def to_s
    @name
  end

  def instance_variables
    super
  end
end

# Recording player double that captures output messages.
class AsetPlayer
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
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AsetCommand environment') do
  @aset_player          = AsetPlayer.new
  @aset_object_ref      = nil
  @aset_attribute       = nil
  @aset_value           = nil
  @aset_target          = nil
  @aset_force           = nil
  @aset_admin_calls     = []
  @aset_find_returns_nil = false

  # Ensure `log` is available as a no-op for the "all" branch (line 20).
  # The production code calls `log` which is a private method on Object
  # defined by aethyr/core/util/log.rb. We avoid loading that module's
  # full dependency chain by defining a lightweight stand-in.
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Provide a room object for $manager.get_object(player.container)
  room_obj = OpenStruct.new(name: "Test Room", goid: "room_goid_1")

  # Build a stub manager that supports get_object, find, find_all
  mgr = Object.new

  # Keep references to test-world state accessible inside the singleton methods.
  player_ref        = @aset_player
  find_nil_flag     = -> { @aset_find_returns_nil }
  target_ref        = -> { @aset_target }
  admin_calls_ref   = @aset_admin_calls

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

  mgr.define_singleton_method(:find_all) do |_attrib, _klass|
    # Return two small stub objects so the each-loop executes
    obj1 = OpenStruct.new(goid: "obj1")
    obj2 = OpenStruct.new(goid: "obj2")
    [obj1, obj2]
  end

  mgr.define_singleton_method(:submit_action) { |_a| }

  $manager = mgr

  # Stub the Admin constant used at line 36.
  # We define it only once and track calls via the shared array.
  unless defined?(::Admin)
    admin_mod = Module.new
    Object.const_set(:Admin, admin_mod)
  end

  # Re-define Admin.aset each scenario so the closure captures the right array.
  ::Admin.define_singleton_method(:aset) do |event, _player, _room|
    admin_calls_ref << event
  end
end

Given('the object reference is {string}') do |ref|
  @aset_object_ref = ref
end

Given('the attribute is {string}') do |attr|
  @aset_attribute = attr
end

Given('the value is {string}') do |val|
  @aset_value = val
end

Given('find_object will return nil') do
  @aset_find_returns_nil = true
end

Given('the force flag is set') do
  @aset_force = true
end

Given('a target object exists for {string}') do |keyword|
  # "here" means the object reference is replaced with player.container in action()
  @aset_target     = AsetTargetObject.new("Test Room")
  @aset_object_ref = keyword
end

Given('a target object exists') do
  @aset_target    = AsetTargetObject.new("shiny gem")
  @aset_object_ref = @aset_target.goid
end

Given('a target object exists with an array attribute {string}') do |ivar|
  @aset_target = AsetTargetObject.new("tagged thing")
  @aset_target.instance_variable_set(ivar.to_sym, ["old_tag"])
  @aset_object_ref = @aset_target.goid
end

Given('a target object exists with a string attribute {string} set to {string}') do |ivar, val|
  @aset_target = AsetTargetObject.new("flagged thing")
  @aset_target.instance_variable_set(ivar.to_sym, val)
  @aset_object_ref = @aset_target.goid
end

Given('a target object exists with an integer attribute {string} set to {int}') do |ivar, val|
  @aset_target = AsetTargetObject.new("counted thing")
  @aset_target.instance_variable_set(ivar.to_sym, val)
  @aset_object_ref = @aset_target.goid
end

Given('the manager has objects of class String') do
  # find_all already returns stubs; nothing extra needed.
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AsetCommand action is invoked') do
  data = {
    object:    @aset_object_ref,
    attribute: @aset_attribute,
    value:     @aset_value
  }
  data[:force] = true if @aset_force

  cmd = Aethyr::Core::Actions::Aset::AsetCommand.new(@aset_player, **data)

  # Patch find_object on this instance so it returns our controlled target.
  target_ref        = -> { @aset_target }
  find_nil_flag     = -> { @aset_find_returns_nil }

  cmd.define_singleton_method(:find_object) do |_name, _event|
    return nil if find_nil_flag.call
    target_ref.call
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the player should see {string}') do |fragment|
  match = @aset_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@aset_player.messages.inspect}")
end

Then('Admin.aset should have been called') do
  assert(!@aset_admin_calls.empty?,
    "Expected Admin.aset to have been called at least once, but it was not.")
end
