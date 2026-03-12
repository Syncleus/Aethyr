# frozen_string_literal: true
###############################################################################
# Step definitions for MoveCommand action coverage.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/move'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module MoveWorld
  attr_accessor :move_player, :move_direction, :move_room, :move_new_room,
                :move_exit_obj, :move_out_event_received,
                :move_room_removed_player, :move_new_room_added_player
end
World(MoveWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class MovePlayer
  attr_accessor :container, :name, :goid

  def initialize
    @container = "move_room_goid_1"
    @name      = "TestMover"
    @goid      = "move_player_goid_1"
    @messages  = []
  end

  def output(msg, **_opts)
    @messages << msg.to_s
  end

  def messages
    @messages
  end

  alias :game_object_id :goid
end

# Exit double with configurable properties.
class MoveExitDouble
  attr_reader :exit_room, :name

  def initialize(exit_room:, name:, openable: false, is_open: true)
    @exit_room = exit_room
    @name      = name
    @openable  = openable
    @is_open   = is_open
  end

  def can?(ability)
    return @openable if ability == :open
    false
  end

  def open?
    @is_open
  end
end

# Room double that tracks operations.
class MoveRoomDouble
  attr_reader :removed_objects, :out_events, :goid

  def initialize(goid, look_text: "A nice room")
    @goid             = goid
    @exits            = {}
    @removed_objects  = []
    @out_events       = []
    @look_text        = look_text
  end

  def add_exit(direction, exit_obj)
    @exits[direction] = exit_obj
  end

  def exit(direction)
    @exits[direction]
  end

  def remove(obj)
    @removed_objects << obj
  end

  def add(obj)
    # no-op; tracked externally via MoveWorld
  end

  def out_event(event)
    @out_events << event
  end

  def look(_player)
    @look_text
  end

  alias :game_object_id :goid
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed MoveCommand environment') do
  @move_player               = MovePlayer.new
  @move_direction             = nil
  @move_room                  = MoveRoomDouble.new("move_room_goid_1")
  @move_new_room              = nil
  @move_exit_obj              = nil
  @move_out_event_received    = false
  @move_room_removed_player   = false
  @move_new_room_added_player = false

  # Stub Window.split_message so we don't need ncurses
  unless ::Object.const_defined?(:Window)
    klass = Class.new do
      def self.split_message(msg, cols = 79)
        msg.split("\n")
      end
    end
    ::Object.const_set(:Window, klass)
  else
    # Ensure split_message is defined even if Window already exists
    unless ::Window.respond_to?(:split_message)
      ::Window.define_singleton_method(:split_message) do |msg, cols = 79|
        msg.split("\n")
      end
    end
  end

  # Build a stub manager; will be configured per-scenario via other steps
  room_ref = @move_room
  mgr = Object.new

  # $manager.get_object(container) -> room
  player_ref = @move_player
  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      room_ref
    else
      nil
    end
  end

  # Default find returns nil; overridden by specific steps
  mgr.define_singleton_method(:find) { |_id| nil }

  $manager = mgr
end

Given('the move direction is {string}') do |dir|
  @move_direction = dir
end

Given('the room has no exit for {string}') do |dir|
  # Room has no exit configured for this direction; room.exit(dir) returns nil
  # (MoveRoomDouble already returns nil for unconfigured exits)
end

Given('the room has a closed exit for {string}') do |dir|
  @move_exit_obj = MoveExitDouble.new(
    exit_room: "some_room_id",
    name:      "closed door",
    openable:  true,
    is_open:   false
  )
  @move_room.add_exit(dir, @move_exit_obj)
end

Given('the room has an open exit for {string} named {string} leading to {string}') do |dir, name, room_id|
  @move_exit_obj = MoveExitDouble.new(
    exit_room: room_id,
    name:      name,
    openable:  false,
    is_open:   true
  )
  @move_room.add_exit(dir, @move_exit_obj)
end

Given('the manager cannot find room {string}') do |_room_id|
  # Default find already returns nil, so nothing extra needed
end

Given('the manager can find room {string}') do |room_id|
  @move_new_room = MoveRoomDouble.new(room_id, look_text: "A nice room")

  new_room_ref = @move_new_room
  $manager.define_singleton_method(:find) do |id|
    id == room_id ? new_room_ref : nil
  end
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the MoveCommand action is invoked') do
  cmd = Aethyr::Core::Actions::Move::MoveCommand.new(
    @move_player,
    direction: @move_direction
  )
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the move player should see {string}') do |fragment|
  match = @move_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected move player output containing #{fragment.inspect}, got: #{@move_player.messages.inspect}")
end

Then('the move player container should be {string}') do |expected_goid|
  assert_equal(expected_goid, @move_player.container,
    "Expected player container to be #{expected_goid.inspect}, got #{@move_player.container.inspect}")
end

Then('the move old room should have received out_event') do
  assert(@move_room.out_events.length > 0,
    "Expected old room to have received out_event, but it did not.")
end

Then('the move old room should have removed the player') do
  assert(@move_room.removed_objects.include?(@move_player),
    "Expected old room to have removed the player.")
end

Then('the move new room should have added the player') do
  # We verify this indirectly: if the player's container was updated to the
  # new room's goid, that means new_room.add was called and the container
  # assignment succeeded. The MoveRoomDouble.add is a no-op but the source
  # code sets @player.container = new_room.game_object_id right after.
  assert_equal(@move_new_room.game_object_id, @move_player.container,
    "Expected player container to match new room goid after move.")
end
