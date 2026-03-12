# frozen_string_literal: true

###############################################################################
# Step definitions for the Respawns trait feature.                            #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'

# ---------------------------------------------------------------------------
# Lightweight stub classes used by the Respawns module's `case` statement.
# Guarded so they never collide with the real classes if loaded elsewhere.
# ---------------------------------------------------------------------------
unless defined?(Area)
  class Area
    attr_accessor :inventory
  end
end

unless defined?(Room)
  class Room; end
end

unless defined?(Container)
  class Container; end
end

# ---------------------------------------------------------------------------
# Require the module under test *after* the stub classes are defined so that
# the constant references in the case/when branches resolve correctly.
# ---------------------------------------------------------------------------
require 'aethyr/core/objects/traits/respawns'

World(Test::Unit::Assertions)

###############################################################################
# A minimal fake $manager that maps IDs to objects.                           #
###############################################################################
module RespawnsTestWorld
  class FakeManager
    attr_accessor :objects

    def initialize
      @objects = {}
    end

    def get_object(id)
      @objects[id]
    end

    def existing_goid?(id)
      @objects.key?(id)
    end
  end

  # -------------------------------------------------------------------------
  # Base class that satisfies the interface Respawns expects (info, alive,
  # log, run) without pulling in the real GameObject hierarchy.
  # -------------------------------------------------------------------------
  class RespawnsTestBase
    attr_accessor :info, :log_messages

    def initialize(*args)
      opts = args.first.is_a?(Hash) ? args.first : {}
      @info = OpenStruct.new
      @log_messages = []
      @container = opts[:container]
      @_alive = true
    end

    def alive
      @_alive
    end

    def alive=(val)
      @_alive = val
    end

    def log(msg)
      @log_messages << msg
    end

    def run; end
  end

  class RespawnsTestObject < RespawnsTestBase
    include Respawns
  end

  # -------------------------------------------------------------------------
  # A generic Enumerable (not Area/Room/Container) for the case branch.
  # -------------------------------------------------------------------------
  class GenericEnumerable
    include Enumerable

    attr_accessor :inventory

    def initialize(inv = nil)
      @inventory = inv
      @items = []
    end

    def each(&block)
      @items.each(&block)
    end
  end

  # -------------------------------------------------------------------------
  # Factory helpers that create instances passing `is_a?` checks for the
  # real or stub Area/Room/Container classes, regardless of which is loaded.
  # We allocate to skip complex real constructors, then set inventory.
  # -------------------------------------------------------------------------
  def rspwn_make_area(inv = [])
    obj = Area.allocate
    # Ensure inventory accessor exists even if the real class has one via attr_reader
    obj.instance_variable_set(:@inventory, inv)
    # Define a getter if the real class doesn't expose one accessibly
    unless obj.respond_to?(:inventory)
      class << obj; attr_reader :inventory; end
    end
    obj
  end

  def rspwn_make_room
    Room.allocate
  end

  def rspwn_make_container
    Container.allocate
  end

  attr_accessor :rspwn_object, :rspwn_error, :rspwn_manager
end
World(RespawnsTestWorld)

###############################################################################
# Before / After hooks – isolate $manager per scenario                        #
###############################################################################
Before('@respawns') do
  self.rspwn_manager = RespawnsTestWorld::FakeManager.new
  $manager = rspwn_manager
end

After('@respawns') do
  $manager = nil
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('I have a respawns test object with container {string}') do |cid|
  self.rspwn_object = RespawnsTestWorld::RespawnsTestObject.new(container: cid)
end

Given('I have a respawns test object without container') do
  self.rspwn_object = RespawnsTestWorld::RespawnsTestObject.new
end

Given('the respawns object is alive') do
  rspwn_object.alive = true
end

Given('the respawns object is not alive') do
  rspwn_object.alive = false
end

Given('the respawns object respawn_time is in the past') do
  rspwn_object.info.respawn_time = (Time.now.to_i - 100)
end

Given('the respawns object respawn_time is in the future') do
  rspwn_object.info.respawn_time = (Time.now.to_i + 9999)
end

# ── Enumerable respawn_area returning an Area with real rooms ──────────────
Given('the respawns object has an enumerable respawn_area returning an Area with rooms') do
  room_obj = rspwn_make_room
  area_obj = rspwn_make_area([:room_id_1])
  rspwn_manager.objects[:area_id_1] = area_obj
  rspwn_manager.objects[:room_id_1] = room_obj

  # respawn_area is a Set-like Enumerable of area IDs
  rspwn_object.info.respawn_area = [:area_id_1]
end

# ── Enumerable respawn_area returning an Area where room lookup is nil ─────
Given('the respawns object has an enumerable respawn_area returning an Area with nil room') do
  area_obj = rspwn_make_area([:missing_room_id])
  rspwn_manager.objects[:area_id_nil] = area_obj
  # Do NOT register :missing_room_id → get_object returns nil

  rspwn_object.info.respawn_area = [:area_id_nil]
end

# ── Direct (non-Enumerable) respawn_area returning a Room ─────────────────
Given('the respawns object has a direct respawn_area returning a Room') do
  room_obj = rspwn_make_room
  rspwn_manager.objects[:direct_room] = room_obj

  rspwn_object.info.respawn_area = :direct_room
end

# ── Direct respawn_area returning a Container ─────────────────────────────
Given('the respawns object has a direct respawn_area returning a Container') do
  container_obj = rspwn_make_container
  rspwn_manager.objects[:direct_container] = container_obj

  rspwn_object.info.respawn_area = :direct_container
end

# ── Direct respawn_area returning an Area with rooms ──────────────────────
Given('the respawns object has a direct respawn_area returning an Area with rooms') do
  room_obj = rspwn_make_room
  area_obj = rspwn_make_area([:room_from_area])
  rspwn_manager.objects[:direct_area] = area_obj
  rspwn_manager.objects[:room_from_area] = room_obj

  rspwn_object.info.respawn_area = :direct_area
end

# ── Direct respawn_area returning a generic Enumerable ────────────────────
Given('the respawns object has a direct respawn_area returning a generic Enumerable') do
  room_obj = rspwn_make_room
  gen_enum = RespawnsTestWorld::GenericEnumerable.new(:enum_room)
  rspwn_manager.objects[:gen_enum_area] = gen_enum
  rspwn_manager.objects[:enum_room] = room_obj

  rspwn_object.info.respawn_area = :gen_enum_area
end

# ── Direct respawn_area returning an unknown type (plain Object) ──────────
Given('the respawns object has a direct respawn_area returning an unknown type') do
  unknown_obj = Object.new
  rspwn_manager.objects[:unknown_area] = unknown_obj

  rspwn_object.info.respawn_area = :unknown_area
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('I run the respawns object') do
  rspwn_object.run
end

When('I run the respawns object expecting respawn') do
  # respawn may log and return without raising – just run normally
  self.rspwn_error = nil
  begin
    rspwn_object.run
  rescue RuntimeError => e
    self.rspwn_error = e
  end
end

When('I run the respawns object expecting raise {string}') do |_msg|
  self.rspwn_error = nil
  begin
    rspwn_object.run
  rescue RuntimeError => e
    self.rspwn_error = e
  end
end

When('I call respawns respawn_in with {int} seconds') do |seconds|
  rspwn_object.respawn_in(seconds)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the respawns object respawn_area should be {string}') do |expected|
  assert_equal(expected, rspwn_object.info.respawn_area)
end

Then('the respawns object respawn_area should be nil') do
  assert_nil(rspwn_object.info.respawn_area)
end

Then('the respawns object respawn_rate should be {int}') do |rate|
  assert_equal(rate, rspwn_object.info.respawn_rate)
end

Then('the respawns object respawn_time should be nil') do
  assert_nil(rspwn_object.info.respawn_time)
end

Then('the respawns object should have no log messages') do
  assert(rspwn_object.log_messages.empty?,
         "Expected no log messages, got: #{rspwn_object.log_messages.inspect}")
end

Then('the respawns object log should include {string}') do |substring|
  matched = rspwn_object.log_messages.any? { |m| m.include?(substring) }
  assert(matched,
         "Expected log to include '#{substring}', got: #{rspwn_object.log_messages.inspect}")
end

Then('the respawns object respawn_time should be approximately {int} seconds from now') do |seconds|
  expected = (Time.now + seconds).to_i
  actual = rspwn_object.info.respawn_time
  assert_not_nil(actual, 'Expected respawn_time to be set')
  assert((expected - actual).abs <= 2,
         "Expected respawn_time ~#{expected}, got #{actual}")
end

Then('the respawns raised error message should include {string}') do |substring|
  assert_not_nil(rspwn_error,
                 "Expected a RuntimeError but none was raised. Logs: #{rspwn_object.log_messages.inspect}")
  assert(rspwn_error.message.include?(substring),
         "Expected error message to include '#{substring}', got '#{rspwn_error.message}'")
end
