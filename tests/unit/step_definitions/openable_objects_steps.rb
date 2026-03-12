# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step definitions for the Openable trait feature.
#
# We build lightweight test doubles that avoid pulling in the full game-engine
# dependency tree while still exercising every branch inside Openable.
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'aethyr/core/objects/traits/openable'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# Test doubles
# ---------------------------------------------------------------------------

# Minimal mock player that records output messages.
class OpenableMockPlayer
  attr_accessor :name, :room

  def initialize(name = "Tester")
    @name    = name
    @room    = "room_goid_1"
    @outputs = []
  end

  def output(message, *_args)
    @outputs << message.to_s
  end

  def last_output
    @outputs.last
  end

  def all_output
    @outputs.join("\n")
  end
end

# Minimal mock room that records output messages.
class OpenableMockRoom
  def initialize
    @outputs = []
  end

  def output(message, *_args)
    @outputs << message.to_s
  end

  def last_output
    @outputs.last
  end

  def all_output
    @outputs.join("\n")
  end
end

# Minimal stub manager that provides #find and other expected methods.
class OpenableStubManager
  attr_accessor :objects

  def initialize
    @objects = {}
  end

  def find(goid, *_args)
    @objects[goid]
  end

  def submit_action(action)
    # no-op
  end

  def existing_goid?(_goid)
    false
  end
end

# ---------------------------------------------------------------------------
# Base class for openable test objects.  Provides the bare minimum
# initialisation chain that Openable#initialize expects (via super).
# ---------------------------------------------------------------------------
class OpenableTestBase
  attr_accessor :name, :generic, :article

  def initialize(*_args)
    @name    = ""
    @generic = "chest"
    @article = "a"
  end

  # Mimic GameObject#can? which is aliased to respond_to?
  alias :can? :respond_to?
end

# Concrete test class that includes Openable.
class OpenableTestObject < OpenableTestBase
  include Openable

  # Expose internals for direct manipulation in tests.
  attr_writer :locked, :open, :lockable
end

# Test class with a connected_to relationship for lock/unlock propagation.
class OpenableConnectedObject < OpenableTestBase
  include Openable

  attr_accessor :connected_to
  attr_writer :locked, :open, :lockable
end

# Class used to test the Openable.included hook that wraps look_inside.
# The look_inside instance method is defined BEFORE including Openable.
# We also define a class-level respond_to? override so that
# `klass.respond_to?(:look_inside)` returns true (matching the guard in
# Openable.included).
class OpenableLookInsideTest < OpenableTestBase
  # Instance method that will be wrapped by Openable.included.
  def look_inside(event)
    event[:result] = :original_called
  end

  # Make the *class* respond to :look_inside so the guard passes.
  def self.respond_to?(method, include_all = false)
    return true if method == :look_inside
    super
  end

  include Openable

  attr_writer :open
end

# ---------------------------------------------------------------------------
# World module – keeps scenario state isolated per scenario.
# ---------------------------------------------------------------------------
module OpenableWorld
  attr_accessor :openable_obj, :openable_player, :openable_room,
                :openable_lock_result, :openable_unlock_result,
                :openable_connected_obj, :openable_manager
end
World(OpenableWorld)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def setup_openable_manager(room)
  mgr = OpenableStubManager.new
  mgr.objects["room_goid_1"] = room
  $manager = mgr
  self.openable_manager = mgr
  mgr
end

# ---------------------------------------------------------------------------
# GIVEN steps
# ---------------------------------------------------------------------------

Given('an openable object') do
  self.openable_room   = OpenableMockRoom.new
  self.openable_player = OpenableMockPlayer.new
  self.openable_obj    = OpenableTestObject.new
  setup_openable_manager(openable_room)
end

Given('an openable object with name {string}') do |name|
  self.openable_room   = OpenableMockRoom.new
  self.openable_player = OpenableMockPlayer.new
  self.openable_obj    = OpenableTestObject.new
  openable_obj.name    = name
  setup_openable_manager(openable_room)
end

Given('an openable object with no name') do
  self.openable_room   = OpenableMockRoom.new
  self.openable_player = OpenableMockPlayer.new
  self.openable_obj    = OpenableTestObject.new
  openable_obj.name    = ""  # empty name triggers article+generic path
  setup_openable_manager(openable_room)
end

Given('an openable object that is already open') do
  self.openable_room   = OpenableMockRoom.new
  self.openable_player = OpenableMockPlayer.new
  self.openable_obj    = OpenableTestObject.new
  openable_obj.open    = true
  setup_openable_manager(openable_room)
end

Given('an openable object that is locked') do
  self.openable_room   = OpenableMockRoom.new
  self.openable_player = OpenableMockPlayer.new
  self.openable_obj    = OpenableTestObject.new
  openable_obj.locked  = true
  setup_openable_manager(openable_room)
end

Given('an openable object with name {string} that is open') do |name|
  self.openable_room   = OpenableMockRoom.new
  self.openable_player = OpenableMockPlayer.new
  self.openable_obj    = OpenableTestObject.new
  openable_obj.name    = name
  openable_obj.open    = true
  setup_openable_manager(openable_room)
end

Given('an openable object with no name that is open') do
  self.openable_room   = OpenableMockRoom.new
  self.openable_player = OpenableMockPlayer.new
  self.openable_obj    = OpenableTestObject.new
  openable_obj.name    = ""
  openable_obj.open    = true
  setup_openable_manager(openable_room)
end

Given('an openable lockable object with key {string}') do |key|
  self.openable_room   = OpenableMockRoom.new
  self.openable_player = OpenableMockPlayer.new
  self.openable_obj    = OpenableTestObject.new
  openable_obj.lockable = true
  openable_obj.keys     = [key]
  setup_openable_manager(openable_room)
end

Given('an openable lockable object with key {string} that is locked') do |key|
  self.openable_room   = OpenableMockRoom.new
  self.openable_player = OpenableMockPlayer.new
  self.openable_obj    = OpenableTestObject.new
  openable_obj.lockable = true
  openable_obj.locked   = true
  openable_obj.keys     = [key]
  setup_openable_manager(openable_room)
end

Given('an openable lockable object with key {string} connected to another lockable object') do |key|
  self.openable_room   = OpenableMockRoom.new
  self.openable_player = OpenableMockPlayer.new

  # The "other" connected object.
  self.openable_connected_obj = OpenableConnectedObject.new
  openable_connected_obj.lockable = true
  openable_connected_obj.keys     = [key]

  # Primary object with a connected_to reference.
  self.openable_obj = OpenableConnectedObject.new
  openable_obj.lockable     = true
  openable_obj.keys         = [key]
  openable_obj.connected_to = "connected_goid"

  mgr = setup_openable_manager(openable_room)
  mgr.objects["connected_goid"] = openable_connected_obj
end

Given('an openable lockable object with key {string} connected to another locked object') do |key|
  self.openable_room   = OpenableMockRoom.new
  self.openable_player = OpenableMockPlayer.new

  # The "other" connected object – starts locked.
  self.openable_connected_obj = OpenableConnectedObject.new
  openable_connected_obj.lockable = true
  openable_connected_obj.locked   = true
  openable_connected_obj.keys     = [key]

  # Primary object – also locked and connected.
  self.openable_obj = OpenableConnectedObject.new
  openable_obj.lockable     = true
  openable_obj.locked       = true
  openable_obj.keys         = [key]
  openable_obj.connected_to = "connected_goid"

  mgr = setup_openable_manager(openable_room)
  mgr.objects["connected_goid"] = openable_connected_obj
end

Given('an openable object class with a look_inside method') do
  self.openable_room   = OpenableMockRoom.new
  self.openable_player = OpenableMockPlayer.new
  self.openable_obj    = OpenableLookInsideTest.new
  setup_openable_manager(openable_room)
end

# ---------------------------------------------------------------------------
# WHEN steps
# ---------------------------------------------------------------------------

When('the openable object is opened by {string}') do |player_name|
  openable_player.name = player_name
  openable_obj.open({ player: openable_player })
end

When('the openable object is closed by {string}') do |player_name|
  openable_player.name = player_name
  openable_obj.close({ player: openable_player })
end

When('the openable object is locked with key {string}') do |key|
  self.openable_lock_result = openable_obj.lock(key)
end

When('the openable object is locked with admin override') do
  self.openable_lock_result = openable_obj.lock("no_such_key", true)
end

When('the openable object is unlocked with key {string}') do |key|
  self.openable_unlock_result = openable_obj.unlock(key)
end

When('the openable object is unlocked with admin override') do
  self.openable_unlock_result = openable_obj.unlock("no_such_key", true)
end

When('the openable look_inside object is open and look_inside is called') do
  openable_obj.open = true
  @openable_look_event = { player: openable_player }
  openable_obj.look_inside(@openable_look_event)
end

When('the openable look_inside object is closed and look_inside is called') do
  openable_obj.open = false
  @openable_look_event = { player: openable_player }
  openable_obj.look_inside(@openable_look_event)
end

# ---------------------------------------------------------------------------
# THEN steps
# ---------------------------------------------------------------------------

Then('the openable object should not be open') do
  assert_equal false, openable_obj.open?
end

Then('the openable object should be open') do
  assert_equal true, openable_obj.open?
end

Then('the openable object should be closed') do
  assert_equal true, openable_obj.closed?
end

Then('the openable object should not be closed') do
  assert_equal false, openable_obj.closed?
end

Then('the openable object should not be locked') do
  assert_equal false, openable_obj.locked?
end

Then('the openable object should be locked') do
  assert_equal true, openable_obj.locked?
end

Then('the openable object should not be lockable') do
  assert_equal false, openable_obj.lockable?
end

Then('the openable object should report openable as true') do
  assert_equal true, openable_obj.openable?
end

Then('the openable object keys should be empty') do
  assert_equal [], openable_obj.keys
end

Then('the openable player output should include {string}') do |expected|
  actual = openable_player.all_output
  assert(actual.include?(expected),
         "Expected player output to include #{expected.inspect}, got: #{actual.inspect}")
end

Then('the openable room output should include {string}') do |expected|
  actual = openable_room.all_output
  assert(actual.include?(expected),
         "Expected room output to include #{expected.inspect}, got: #{actual.inspect}")
end

Then('the openable lock result should be true') do
  assert_equal true, openable_lock_result
end

Then('the openable lock result should be false') do
  assert_equal false, openable_lock_result
end

Then('the openable unlock result should be true') do
  assert_equal true, openable_unlock_result
end

Then('the openable unlock result should be false') do
  assert_equal false, openable_unlock_result
end

Then('the openable connected object should also be locked') do
  assert_equal true, openable_connected_obj.locked?
end

Then('the openable connected object should also be unlocked') do
  assert_equal false, openable_connected_obj.locked?
end

Then('the openable look_inside should delegate to the original method') do
  assert_equal :original_called, @openable_look_event[:result],
               "Expected the original look_inside to be called when object is open"
end
