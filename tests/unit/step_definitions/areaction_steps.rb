# frozen_string_literal: true
###############################################################################
# Step definitions for AreactionCommand action coverage.                      #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/areaction'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AreactionWorld
  attr_accessor :areaction_player, :areaction_command, :areaction_object,
                :areaction_action_name, :areaction_file, :areaction_target,
                :areaction_find_returns_nil, :areaction_admin_calls,
                :areaction_file_exists_map, :areaction_room_obj
end
World(AreactionWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AreactionPlayer
  attr_accessor :container, :name, :goid

  def initialize
    @container = "room_goid_1"
    @name      = "TestAdmin"
    @goid      = "player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def messages
    @messages
  end
end

# Mock actions collection that supports add?, delete?, empty?, to_a
class AreactionActionsSet
  def initialize(items = [], add_result: true, delete_result: true)
    @items = items.dup
    @add_result = add_result
    @delete_result = delete_result
  end

  def add?(name)
    @add_result
  end

  def delete?(name)
    @delete_result
  end

  def empty?
    @items.empty?
  end

  def to_a
    @items
  end
end

# Flexible mock game object for areaction targets.
class AreactionTargetObject
  attr_accessor :name, :goid, :actions

  def initialize(name = "test object", opts = {})
    @name = name
    @goid = opts[:goid] || "target_goid_123"
    @actions = opts[:actions] || nil
    @is_reacts = opts[:is_reacts] || false
    @capabilities = opts[:capabilities] || {}
    @reaction_text = opts[:reaction_text] || "reactions listed"
  end

  def is_a?(klass)
    if klass == AreactionReacts
      @is_reacts
    else
      super
    end
  end

  def can?(method_name)
    respond_to?(method_name)
  end

  # Define these dynamically based on configuration
  def to_s
    @name
  end
end

###############################################################################
# Stub Reacts module – avoids loading the full dependency chain               #
###############################################################################
# We define a simple module to stand in for the real Reacts module.
# We need it to exist as a constant so `object.is_a? Reacts` and
# `$manager.find_all("class", Reacts)` work properly.
AreactionReacts = Module.new

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AreactionCommand environment') do
  @areaction_player          = AreactionPlayer.new
  @areaction_command         = nil
  @areaction_object          = nil
  @areaction_action_name     = nil
  @areaction_file            = nil
  @areaction_target          = nil
  @areaction_find_returns_nil = false
  @areaction_admin_calls     = []
  @areaction_file_exists_map = {}

  # Ensure `log` is available as a no-op
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Provide a room object for $manager.get_object(player.container)
  @areaction_room_obj = AreactionTargetObject.new("Test Room", goid: "room_goid_1")
  room_obj = @areaction_room_obj

  # Build a stub manager
  mgr = Object.new
  player_ref        = @areaction_player
  find_nil_flag     = -> { @areaction_find_returns_nil }
  target_ref        = -> { @areaction_target }
  admin_calls_ref   = @areaction_admin_calls

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

  # find_all returns stub objects that support reload_reactions
  mgr.define_singleton_method(:find_all) do |_attrib, _klass|
    obj1 = Object.new
    obj1.define_singleton_method(:reload_reactions) { }
    obj1.define_singleton_method(:goid) { "obj1" }
    obj1.define_singleton_method(:to_s) { "obj1" }
    obj2 = Object.new
    obj2.define_singleton_method(:reload_reactions) { }
    obj2.define_singleton_method(:goid) { "obj2" }
    obj2.define_singleton_method(:to_s) { "obj2" }
    [obj1, obj2]
  end

  $manager = mgr

  # Stub the Admin constant
  unless defined?(::Admin)
    admin_mod = Module.new
    Object.const_set(:Admin, admin_mod)
  end

  # Re-define Admin.areaction each scenario so the closure captures the right array.
  ::Admin.define_singleton_method(:areaction) do |event, _player, _room|
    admin_calls_ref << event
  end

  # Stub the Reacts constant at top level if not already defined
  unless defined?(::Reacts)
    Object.const_set(:Reacts, AreactionReacts)
  end
end

Given('the areaction command is {string}') do |cmd|
  @areaction_command = cmd
end

Given('the areaction object is {string}') do |obj|
  @areaction_object = obj
end

Given('the areaction action_name is {string}') do |name|
  @areaction_action_name = name
end

Given('the areaction file is {string}') do |file|
  @areaction_file = file
end

# Configure the room object to support show_reactions (for "here" scenario)
Given('the areaction room supports show_reactions') do
  room = @areaction_room_obj
  room.actions = AreactionActionsSet.new([])
  room.define_singleton_method(:show_reactions) { "reactions listed" }
end

Given('areaction find_object will return nil') do
  @areaction_find_returns_nil = true
end

Given('the reaction file {string} exists') do |file|
  @areaction_file_exists_map[file] = true
end

Given('the reaction file {string} does not exist') do |file|
  @areaction_file_exists_map[file] = false
end

# Target that supports add? returning true
Given('a areaction target object exists with add returning true') do
  @areaction_target = AreactionTargetObject.new("target thing",
    goid: "target_goid_123",
    is_reacts: true,
    actions: AreactionActionsSet.new(["existing"], add_result: true))
end

# Target that supports add? returning false
Given('a areaction target object exists with add returning false') do
  @areaction_target = AreactionTargetObject.new("target thing",
    goid: "target_goid_123",
    is_reacts: true,
    actions: AreactionActionsSet.new(["existing"], add_result: false))
end

# Target that supports delete? returning true
Given('a areaction target object exists with delete returning true') do
  @areaction_target = AreactionTargetObject.new("target thing",
    goid: "target_goid_123",
    is_reacts: true,
    actions: AreactionActionsSet.new(["existing"], delete_result: true))
end

# Target that supports delete? returning false
Given('a areaction target object exists with delete returning false') do
  @areaction_target = AreactionTargetObject.new("target thing",
    goid: "target_goid_123",
    is_reacts: true,
    actions: AreactionActionsSet.new(["existing"], delete_result: false))
end

# Target that is a Reacts object (supports load_reactions, reload_reactions, unload_reactions, show_reactions)
Given('a areaction target object exists that is Reacts') do
  @areaction_target = AreactionTargetObject.new("target thing",
    goid: "target_goid_123",
    is_reacts: true,
    actions: AreactionActionsSet.new([]))

  target = @areaction_target
  target.define_singleton_method(:load_reactions) { |_file| }
  target.define_singleton_method(:reload_reactions) { }
  target.define_singleton_method(:unload_reactions) { }
  target.define_singleton_method(:show_reactions) { "reactions listed" }
  target.define_singleton_method(:extend) { |_mod| }
end

# Target that is NOT a Reacts object - for testing the extend(Reacts) branch
Given('a areaction target object exists without Reacts') do
  @areaction_target = AreactionTargetObject.new("target thing",
    goid: "target_goid_123",
    is_reacts: false,
    actions: AreactionActionsSet.new([]))

  target = @areaction_target
  target.define_singleton_method(:load_reactions) { |_file| }
  target.define_singleton_method(:reload_reactions) { }
  target.define_singleton_method(:unload_reactions) { }
  target.define_singleton_method(:show_reactions) { "reactions listed" }
  # Stub extend to avoid actually extending with Reacts
  target.define_singleton_method(:extend) { |_mod| }
end

# Target that supports show_reactions
Given('the areaction target object supports show_reactions') do
  @areaction_target = AreactionTargetObject.new("target thing",
    goid: "target_goid_123",
    is_reacts: true,
    actions: AreactionActionsSet.new([]))

  target = @areaction_target
  target.define_singleton_method(:show_reactions) { "reactions listed" }
end

# Target that does NOT support show_reactions
Given('a areaction target object exists without show_reactions') do
  @areaction_target = AreactionTargetObject.new("target thing",
    goid: "target_goid_123",
    is_reacts: true,
    actions: AreactionActionsSet.new([]))
  # Deliberately NOT defining show_reactions
end

# Target with custom non-empty actions
Given('a areaction target object exists with custom actions') do
  @areaction_target = AreactionTargetObject.new("target thing",
    goid: "target_goid_123",
    is_reacts: true,
    actions: AreactionActionsSet.new(["wave", "nod"]))

  target = @areaction_target
  target.define_singleton_method(:show_reactions) { "reactions listed" }
end

# Target with empty actions but supports show_reactions
Given('a areaction target object exists with empty actions and show_reactions') do
  @areaction_target = AreactionTargetObject.new("target thing",
    goid: "target_goid_123",
    is_reacts: true,
    actions: AreactionActionsSet.new([]))

  target = @areaction_target
  target.define_singleton_method(:show_reactions) { "reactions listed" }
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AreactionCommand action is invoked') do
  data = {
    command:     @areaction_command,
    object:      @areaction_object,
    action_name: @areaction_action_name,
    file:        @areaction_file
  }

  cmd = Aethyr::Core::Actions::Areaction::AreactionCommand.new(@areaction_player, **data)

  # Patch find_object on this instance so it returns our controlled target.
  target_ref    = -> { @areaction_target }
  find_nil_flag = -> { @areaction_find_returns_nil }

  cmd.define_singleton_method(:find_object) do |_name, _event|
    return nil if find_nil_flag.call
    target_ref.call
  end

  # Patch File.exist? for the "load" branch
  file_map = @areaction_file_exists_map
  original_file_exist = File.method(:exist?)

  File.define_singleton_method(:exist?) do |path|
    # Check if this matches any of our test files
    file_map.each do |name, exists|
      if path == "objects/reactions/#{name}.rx"
        return exists
      end
    end
    original_file_exist.call(path)
  end

  begin
    cmd.action
  ensure
    # Restore File.exist?
    File.define_singleton_method(:exist?, original_file_exist)
  end
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the areaction player should see {string}') do |fragment|
  match = @areaction_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@areaction_player.messages.inspect}")
end

Then('Admin.areaction should have been called') do
  assert(!@areaction_admin_calls.empty?,
    "Expected Admin.areaction to have been called at least once, but it was not.")
end
