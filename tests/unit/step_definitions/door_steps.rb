# frozen_string_literal: true
###############################################################################
# Step definitions for Door game object coverage.                             #
#                                                                             #
# Exercises lib/aethyr/core/objects/door.rb using lightweight test doubles.   #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module -- scenario-scoped state.
# ---------------------------------------------------------------------------
module DoorTestWorld
  attr_accessor :door_obj, :door_a, :door_b,
                :door_mock_room, :door_mock_player,
                :door_other_side, :door_other_side_calls
end
World(DoorTestWorld)

# ---------------------------------------------------------------------------
# Stub manager -- must exist BEFORE Door (via GameObject) is instantiated.
# Supports configurable #find results keyed by first argument.
# ---------------------------------------------------------------------------
unless defined?(DoorStubManager)
  class DoorStubManager
    attr_accessor :find_map

    def initialize
      @find_map = {}
    end

    def existing_goid?(_goid)
      false
    end

    # $manager.find is called with 1 arg (goid) or 2 args (goid, nil).
    # Return whatever is registered in find_map for the first arg.
    def find(id, *_rest)
      @find_map[id]
    end

    def submit_action(_action); end
  end
end

# ---------------------------------------------------------------------------
# Ensure ServerConfig exists (needed by some code paths).
# ---------------------------------------------------------------------------
unless defined?(::ServerConfig)
  module ::ServerConfig
    @data = {}
    class << self
      def [](key);       @data[key]; end
      def []=(key, val); @data[key] = val; end
    end
  end
end

# ---------------------------------------------------------------------------
# Set $manager before requiring the Door class.
# ---------------------------------------------------------------------------
$manager ||= DoorStubManager.new

# ---------------------------------------------------------------------------
# Mock room -- records output calls.
# ---------------------------------------------------------------------------
class DoorMockRoom
  attr_reader :messages

  def initialize
    @messages = []
  end

  def output(msg, *_args)
    @messages << msg
  end

  def name
    "Mock Room"
  end
end

# ---------------------------------------------------------------------------
# Mock player -- satisfies Openable#open / #close expectations.
# ---------------------------------------------------------------------------
class DoorMockPlayer
  attr_reader :messages, :name

  def initialize(name = "Tester")
    @name = name
    @messages = []
    @room_id = "player_room_#{rand(99999)}"
  end

  def output(msg, *_args)
    @messages << msg
  end

  def room
    @room_id
  end
end

# ---------------------------------------------------------------------------
# Mock other-side door -- records calls to other_side_opened / closed.
# ---------------------------------------------------------------------------
class DoorMockOtherSide
  attr_reader :opened_called, :closed_called

  def initialize
    @opened_called = false
    @closed_called = false
  end

  def other_side_opened
    @opened_called = true
  end

  def other_side_closed
    @closed_called = true
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################

Given('I require the Door library') do
  require 'aethyr/core/objects/door'
  # Ensure $manager is our stub (may have been replaced by another test file).
  unless $manager.is_a?(DoorStubManager)
    $manager = DoorStubManager.new
  end
  $manager.find_map = {}
end

Given('a new Door') do
  self.door_obj = Aethyr::Core::Objects::Door.new
end

Given('a new Door with connected_to set to {string}') do |goid|
  self.door_obj = Aethyr::Core::Objects::Door.new
  door_obj.instance_variable_set(:@connected_to, goid)
end

Given('a new Door that is closed') do
  self.door_obj = Aethyr::Core::Objects::Door.new
  door_obj.instance_variable_set(:@open, false)
end

Given('a new Door that is open') do
  self.door_obj = Aethyr::Core::Objects::Door.new
  door_obj.instance_variable_set(:@open, true)
end

Given('the door container is set to {string}') do |container_id|
  door_obj.instance_variable_set(:@container, container_id)
end

Given('the manager returns a mock room for {string}') do |room_id|
  self.door_mock_room = DoorMockRoom.new
  $manager.find_map[room_id] = door_mock_room
end

Given('a new Door that is closed and not locked') do
  self.door_obj = Aethyr::Core::Objects::Door.new
  door_obj.instance_variable_set(:@open, false)
  door_obj.instance_variable_set(:@locked, false)
end

Given('a new Door that is closed and locked') do
  self.door_obj = Aethyr::Core::Objects::Door.new
  door_obj.instance_variable_set(:@open, false)
  door_obj.instance_variable_set(:@locked, true)
end

Given('the door is connected to another door {string}') do |other_goid|
  door_obj.instance_variable_set(:@connected_to, other_goid)
end

Given('the manager is set up for open with connected door') do
  # The Openable#open calls $manager.find(player.room, nil) to get the room
  # for output.  Door#open then calls $manager.find(@connected_to) to get
  # the other-side door.
  self.door_mock_player = DoorMockPlayer.new("Hero")
  self.door_mock_room   = DoorMockRoom.new
  self.door_other_side  = DoorMockOtherSide.new

  player_room_id = door_mock_player.room
  other_goid     = door_obj.instance_variable_get(:@connected_to)

  $manager.find_map[player_room_id] = door_mock_room
  $manager.find_map[other_goid]     = door_other_side
end

Given('the manager is set up for open without connected door') do
  self.door_mock_player = DoorMockPlayer.new("Hero")
  self.door_mock_room   = DoorMockRoom.new

  player_room_id = door_mock_player.room
  $manager.find_map[player_room_id] = door_mock_room
end

Given('the manager is set up for close with connected door') do
  self.door_mock_player = DoorMockPlayer.new("Hero")
  self.door_mock_room   = DoorMockRoom.new
  self.door_other_side  = DoorMockOtherSide.new

  player_room_id = door_mock_player.room
  other_goid     = door_obj.instance_variable_get(:@connected_to)

  $manager.find_map[player_room_id] = door_mock_room
  $manager.find_map[other_goid]     = door_other_side
end

Given('the manager is set up for close without connected door') do
  self.door_mock_player = DoorMockPlayer.new("Hero")
  self.door_mock_room   = DoorMockRoom.new

  player_room_id = door_mock_player.room
  $manager.find_map[player_room_id] = door_mock_room
end

Given('two new Doors') do
  self.door_a = Aethyr::Core::Objects::Door.new
  self.door_b = Aethyr::Core::Objects::Door.new
end

Given('two new Doors that are both closed') do
  self.door_a = Aethyr::Core::Objects::Door.new
  self.door_b = Aethyr::Core::Objects::Door.new
  door_a.instance_variable_set(:@open, false)
  door_b.instance_variable_set(:@open, false)
end

Given('two new Doors where both are open') do
  self.door_a = Aethyr::Core::Objects::Door.new
  self.door_b = Aethyr::Core::Objects::Door.new
  door_a.instance_variable_set(:@open, true)
  door_b.instance_variable_set(:@open, true)
end

###############################################################################
# When steps                                                                  #
###############################################################################

When('I create a new Door with default arguments') do
  self.door_obj = Aethyr::Core::Objects::Door.new
end

When('I create a new Door with lockable false') do
  self.door_obj = Aethyr::Core::Objects::Door.new(nil, false)
end

When('I call other_side_opened on the door') do
  door_obj.other_side_opened
end

When('I call other_side_closed on the door') do
  door_obj.other_side_closed
end

When('I call open on the door with a mock event') do
  event = { player: door_mock_player }
  door_obj.open(event)
end

When('I call close on the door with a mock event') do
  event = { player: door_mock_player }
  door_obj.close(event)
end

When('I connect door A to door B') do
  door_a.connect_to(door_b)
end

When('I connect the door to string {string}') do |goid|
  door_obj.connect_to(goid)
end

###############################################################################
# Then steps                                                                  #
###############################################################################

Then('the door generic should be {string}') do |expected|
  assert_equal expected, door_obj.instance_variable_get(:@generic)
end

Then('the door article should be {string}') do |expected|
  assert_equal expected, door_obj.instance_variable_get(:@article)
end

Then('the door should not be connected') do
  assert_equal false, door_obj.connected?
end

Then('the door should be connected') do
  assert_equal true, door_obj.connected?
end

Then('the door should be lockable') do
  assert_equal true, door_obj.instance_variable_get(:@lockable)
end

Then('the door should not be lockable') do
  assert_equal false, door_obj.instance_variable_get(:@lockable)
end

Then('the door keys should be empty') do
  assert_equal [], door_obj.instance_variable_get(:@keys)
end

Then('the door should be a kind of Exit') do
  assert_kind_of Aethyr::Core::Objects::Exit, door_obj
end

Then('the door should be open') do
  assert_equal true, door_obj.open?
end

Then('the door should be closed') do
  assert_equal false, door_obj.open?
end

Then('the mock room should have received output {string}') do |expected|
  assert door_mock_room.messages.include?(expected),
    "Expected room to receive '#{expected}', got: #{door_mock_room.messages.inspect}"
end

Then('the other side door should have received other_side_opened') do
  assert_equal true, door_other_side.opened_called,
    "Expected other side to have received other_side_opened"
end

Then('the other side door should not have received other_side_opened') do
  assert_equal false, door_other_side.opened_called,
    "Expected other side NOT to have received other_side_opened"
end

Then('the other side door should have received other_side_closed') do
  assert_equal true, door_other_side.closed_called,
    "Expected other side to have received other_side_closed"
end

Then('door A connected_to should be door B game_object_id') do
  assert_equal door_b.game_object_id, door_a.instance_variable_get(:@connected_to)
end

Then('door B should be connected') do
  assert_equal true, door_b.connected?
end

Then('door A should be closed') do
  assert_equal false, door_a.open?
end

Then('door A should be open') do
  assert_equal true, door_a.open?
end

Then('the door connected_to should be {string}') do |expected|
  assert_equal expected, door_obj.instance_variable_get(:@connected_to)
end
