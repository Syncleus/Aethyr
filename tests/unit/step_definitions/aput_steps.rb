# frozen_string_literal: true
###############################################################################
# Step definitions for AputCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/aput'
require_relative '../support/test_helpers'

# Ensure the Inventory command module is loaded so that the constant
# Aethyr::Core::Actions::Inventory exists (the production code resolves bare
# `Inventory` to this module, not ::Inventory, when the registry is loaded).
require 'aethyr/core/actions/commands/inventory'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AputWorld
  attr_accessor :aput_player, :aput_object_ref, :aput_container_ref,
                :aput_at, :aput_object, :aput_container,
                :aput_find_object_nil, :aput_find_container_nil,
                :aput_manager_find_nil_for_here, :aput_manager_find_room_for_here,
                :aput_old_container, :aput_old_container_removed
end
World(AputWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AputPlayer
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

# A mock inventory that records add/remove calls.
class AputMockInventory
  attr_reader :items, :removed_items

  def initialize
    @items = []
    @removed_items = []
  end

  def add(object, position = nil)
    @items << { object: object, position: position }
  end

  def remove(object)
    @removed_items << object
  end
end

# Mock game object used as the target object to be moved.
class AputTargetObject
  attr_accessor :name, :goid, :container

  def initialize(name = "test gem", goid = "gem_goid_1")
    @name      = name
    @goid      = goid
    @container = nil
  end

  def to_s
    @name
  end
end

# Ensure GameObject constant is available for the is_a? check (line 17).
unless defined?(::GameObject)
  class ::GameObject
    attr_accessor :name, :goid, :container

    def initialize(name = "game object", goid = "go_goid_1")
      @name      = name
      @goid      = goid
      @container = nil
    end

    def to_s
      @name
    end
  end
end

# Ensure ::Container is defined for the is_a? check (line 57).
# In the Aput module context, bare `Container` resolves to ::Container.
unless defined?(::Container)
  Object.const_set(:Container, Class.new)
end

# A generic container with an inventory attribute (not Inventory or Container).
class AputGenericContainer
  attr_accessor :goid, :name, :inventory

  def initialize(name = "room", goid = "room_goid_2")
    @name      = name
    @goid      = goid
    @inventory = AputMockInventory.new
  end

  def to_s
    @name
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################

Given('a stubbed AputCommand environment') do
  @aput_player                     = AputPlayer.new
  @aput_object_ref                 = nil
  @aput_container_ref              = nil
  @aput_at                         = nil
  @aput_object                     = nil
  @aput_container                  = nil
  @aput_find_object_nil            = false
  @aput_find_container_nil         = false
  @aput_manager_find_nil_for_here  = false
  @aput_manager_find_room_for_here = false
  @aput_old_container              = nil
  @aput_old_container_removed      = false

  # Ensure `log` is available as a no-op
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Build a stub manager
  room_obj = OpenStruct.new(name: "Test Room", goid: "room_goid_1")
  mgr = Object.new
  player_ref = @aput_player

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_obj
    else
      nil
    end
  end

  # $manager.find is used in the "!world" and "here" branches
  aput_world = self
  mgr.define_singleton_method(:find) do |id_or_name|
    if aput_world.aput_manager_find_nil_for_here
      nil
    elsif aput_world.aput_manager_find_room_for_here
      aput_world.aput_container
    elsif aput_world.aput_old_container
      aput_world.aput_old_container
    else
      nil
    end
  end

  $manager = mgr
end

Given('the aput object is a GameObject instance') do
  @aput_object = AputTargetObject.new("shiny gem", "gem_goid_1")
  @aput_object.container = nil
  # Make this specific instance pass the is_a?(GameObject) check in aput.rb line 17.
  # We override on the singleton class so other AputTargetObject instances are unaffected.
  def @aput_object.is_a?(klass)
    return true if klass == ::GameObject
    return true if klass.respond_to?(:name) && klass.name&.end_with?("GameObject")
    super
  end
end

Given('the aput object reference is {string}') do |ref|
  @aput_object_ref = ref
  # Create a default target object unless already set
  if @aput_object.nil?
    @aput_object = AputTargetObject.new("test gem", "gem_goid_1")
  end
end

Given('the aput container reference is {string}') do |ref|
  @aput_container_ref = ref
end

Given('the aput container is a generic object') do
  @aput_container = AputGenericContainer.new("big chest", "chest_goid_1")
end

Given('the aput container is an Inventory') do
  # Inside Aethyr::Core::Actions::Aput, bare `Inventory` resolves to
  # Aethyr::Core::Actions::Inventory (a Module from commands/inventory.rb),
  # NOT ::Inventory (the Gary-based Class).  We include that module so our
  # mock passes the `is_a?` check on line 55 of aput.rb.
  inv_mod = Aethyr::Core::Actions::Inventory
  items = []
  @aput_container = Object.new
  @aput_container.singleton_class.include(inv_mod)
  @aput_container.define_singleton_method(:goid) { "inv_goid_1" }
  @aput_container.define_singleton_method(:name) { "magic bag" }
  @aput_container.define_singleton_method(:add) { |obj, pos = nil| items << { object: obj, position: pos } }
  @aput_container.define_singleton_method(:items) { items }
  @aput_container.define_singleton_method(:to_s) { "magic bag" }
end

Given('the aput container is a Container') do
  # In the Aput module context, bare `Container` resolves to ::Container.
  # We subclass it so `is_a?(::Container)` returns true.
  items = []
  @aput_container = ::Container.new
  @aput_container.define_singleton_method(:goid) { "box_goid_1" }
  @aput_container.define_singleton_method(:name) { "wooden box" }
  @aput_container.define_singleton_method(:add) { |obj| items << obj }
  @aput_container.define_singleton_method(:items) { items }
  @aput_container.define_singleton_method(:to_s) { "wooden box" }
end

Given('aput find_object returns nil for the object') do
  @aput_find_object_nil = true
end

Given('aput find_object returns nil for the container') do
  @aput_find_container_nil = true
end

Given('the aput object has an existing container') do
  old_inv = AputMockInventory.new
  @aput_old_container = OpenStruct.new(
    goid: "old_container_goid",
    inventory: old_inv,
    name: "Old Container"
  )
  @aput_object ||= AputTargetObject.new("test gem", "gem_goid_1")
  @aput_object.container = @aput_old_container.goid
end

Given('the aput object has no existing container') do
  @aput_object ||= AputTargetObject.new("test gem", "gem_goid_1")
  @aput_object.container = nil
end

Given('the aput at parameter is {string}') do |at_val|
  @aput_at = at_val
end

Given('aput manager find returns nil for here') do
  @aput_manager_find_nil_for_here = true
end

Given('aput manager find returns the room for here') do
  @aput_manager_find_room_for_here = true
  @aput_container = AputGenericContainer.new("Test Room", "room_goid_1")
end

###############################################################################
# When steps                                                                  #
###############################################################################

When('the AputCommand action is invoked') do
  data = { in: @aput_container_ref }
  data[:at] = @aput_at

  # Set the object: either a direct GameObject instance or a string reference
  if @aput_object.is_a?(::GameObject)
    data[:object] = @aput_object
  else
    data[:object] = @aput_object_ref || "gem1"
  end

  cmd = Aethyr::Core::Actions::Aput::AputCommand.new(@aput_player, **data)

  # Patch find_object on this instance to return controlled values.
  aput_world = self
  cmd.define_singleton_method(:find_object) do |name, _event|
    # If the name matches the object reference, return the object (or nil if flagged)
    if name == aput_world.aput_object_ref || name == aput_world.aput_player.container
      return nil if aput_world.aput_find_object_nil
      aput_world.aput_object
    else
      # Otherwise it's the container lookup
      return nil if aput_world.aput_find_container_nil
      aput_world.aput_container
    end
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################

Then('the aput player should see {string}') do |fragment|
  match = @aput_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@aput_player.messages.inspect}")
end

Then('the aput player should not see {string}') do |fragment|
  match = @aput_player.messages.any? { |m| m.include?(fragment) }
  assert(!match,
    "Expected player output NOT containing #{fragment.inspect}, got: #{@aput_player.messages.inspect}")
end

Then('the aput object should have been removed from old container') do
  assert(@aput_old_container.inventory.removed_items.include?(@aput_object),
    "Expected object to be removed from old container, but it was not. " \
    "Removed items: #{@aput_old_container.inventory.removed_items.inspect}")
end

Then('the aput object container should be set to the generic container goid') do
  assert_equal(@aput_container.goid, @aput_object.container,
    "Expected object container to be #{@aput_container.goid.inspect}, " \
    "got #{@aput_object.container.inspect}")
end
