# frozen_string_literal: true
###############################################################################
# Step definitions for AcdoorCommand action coverage.                         #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/acdoor'
require 'aethyr/core/util/direction'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# Ensure the AcdoorCommand class has access to opposite_dir at runtime.       #
# The production code calls opposite_dir as an unqualified method, which      #
# is normally available via the wider runtime environment. In isolation we     #
# mix it in explicitly.                                                       #
###############################################################################
unless Aethyr::Core::Actions::Acdoor::AcdoorCommand.include?(Aethyr::Direction)
  Aethyr::Core::Actions::Acdoor::AcdoorCommand.include(Aethyr::Direction)
end

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AcdoorWorld
  attr_accessor :acdoor_player, :acdoor_room, :acdoor_direction,
                :acdoor_exit_room_goid, :acdoor_exit_room_obj,
                :acdoor_manager_stubs, :acdoor_command
end
World(AcdoorWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AcdoorPlayer
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

# Mock room that records out_event calls.
class AcdoorRoom
  attr_accessor :container, :goid, :name
  attr_reader :events

  def initialize(goid, name: "Test Room")
    @goid   = goid
    @name   = name
    @events = []
  end

  def out_event(event)
    @events << event
  end

  def to_s
    @name
  end
end

# Mock door returned by create_object.
class AcdoorDoor
  attr_accessor :goid, :name, :connected_door

  def initialize(goid, name: "a door")
    @goid           = goid
    @name           = name
    @connected_door = nil
  end

  def connect_to(other)
    @connected_door = other
  end

  def to_s
    @name
  end
end

###############################################################################
# Ensure Door and Exit constants are available for the production code.       #
###############################################################################
unless defined?(::Door)
  Door = Class.new
end

unless defined?(::Exit)
  Exit = Class.new do
    attr_accessor :exit_room
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################

Given('a stubbed AcdoorCommand environment') do
  # Ensure `log` is available
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  @acdoor_player = AcdoorPlayer.new
  @acdoor_room   = AcdoorRoom.new("room_goid_1", name: "Origin Room")
  @acdoor_player.container = @acdoor_room.goid

  # Default stubs hash – will be customised by subsequent Given steps.
  @acdoor_manager_stubs = {
    find_object_result: nil,       # what find_object returns for the direction
    exit_room_obj: nil,            # the actual room object for exit_room goid
    other_side: nil,               # result of $manager.find(opposite_dir, exit_room)
    deleted_objects: [],           # track delete_object calls
    created_objects: []            # track create_object calls
  }
end

Given('the acdoor exit_room is set to a valid room') do
  @acdoor_exit_room_obj = AcdoorRoom.new("exit_room_goid_1", name: "Destination Room")
  @acdoor_exit_room_goid = @acdoor_exit_room_obj.goid
  @acdoor_manager_stubs[:exit_room_obj] = @acdoor_exit_room_obj
end

Given('the acdoor exit_room is set to an unknown room') do
  @acdoor_exit_room_goid = "nonexistent_room_goid"
  @acdoor_manager_stubs[:exit_room_obj] = nil
end

Given('the acdoor exit_room is nil') do
  @acdoor_exit_room_goid = nil
end

Given('the acdoor direction is {string}') do |dir|
  @acdoor_direction = dir
end

Given('an existing exit in direction {string} with other side') do |_dir|
  exit_obj = Exit.new
  exit_obj.exit_room = "far_room_goid"
  @acdoor_manager_stubs[:find_object_result] = exit_obj

  @acdoor_exit_room_obj = AcdoorRoom.new("far_room_goid", name: "Far Room")
  @acdoor_manager_stubs[:exit_room_obj] = @acdoor_exit_room_obj

  other_side_exit = Exit.new
  other_side_exit.exit_room = @acdoor_room.goid
  @acdoor_manager_stubs[:other_side] = other_side_exit
end

Given('an existing exit in direction {string} without other side') do |_dir|
  exit_obj = Exit.new
  exit_obj.exit_room = "far_room_goid_2"
  @acdoor_manager_stubs[:find_object_result] = exit_obj

  @acdoor_exit_room_obj = AcdoorRoom.new("far_room_goid_2", name: "Far Room 2")
  @acdoor_manager_stubs[:exit_room_obj] = @acdoor_exit_room_obj

  @acdoor_manager_stubs[:other_side] = nil
end

Given('no existing exit in that direction') do
  @acdoor_manager_stubs[:find_object_result] = nil
end

###############################################################################
# When steps                                                                  #
###############################################################################

When('the AcdoorCommand action is invoked') do
  stubs   = @acdoor_manager_stubs
  room    = @acdoor_room
  player  = @acdoor_player
  create_counter = [0]

  mgr = Object.new

  # get_object: returns room for player.container, exit_room_obj for exit_room goid
  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player.container
      room
    elsif stubs[:exit_room_obj] && stubs[:exit_room_obj].respond_to?(:goid) && goid == stubs[:exit_room_obj].goid
      stubs[:exit_room_obj]
    else
      nil
    end
  end

  # find: used for $manager.find(exit_room_goid) and $manager.find(opposite_dir, exit_room_goid)
  mgr.define_singleton_method(:find) do |*args|
    if args.length == 1
      # $manager.find out.exit_room → return the exit room object
      goid = args[0]
      if stubs[:exit_room_obj] && stubs[:exit_room_obj].respond_to?(:goid) && goid == stubs[:exit_room_obj].goid
        stubs[:exit_room_obj]
      else
        nil
      end
    elsif args.length == 2
      # $manager.find opposite_dir(direction), exit_room_goid → return other_side
      stubs[:other_side]
    else
      nil
    end
  end

  # delete_object: record deletions
  mgr.define_singleton_method(:delete_object) do |obj|
    stubs[:deleted_objects] << obj
  end

  # create_object: return Door doubles
  mgr.define_singleton_method(:create_object) do |klass, *args|
    create_counter[0] += 1
    vars = args.last.is_a?(Hash) ? args.last : {}
    door_name = vars[:@name] || "a door #{create_counter[0]}"
    door = AcdoorDoor.new("door_goid_#{create_counter[0]}", name: door_name)
    stubs[:created_objects] << door
    door
  end

  $manager = mgr

  data = { direction: @acdoor_direction }
  data[:exit_room] = @acdoor_exit_room_goid if @acdoor_exit_room_goid

  @acdoor_command = Aethyr::Core::Actions::Acdoor::AcdoorCommand.new(@acdoor_player, **data)

  # Stub find_object on the command instance to return our configured result
  find_result = stubs[:find_object_result]
  @acdoor_command.define_singleton_method(:find_object) do |_name, _event|
    find_result
  end

  @acdoor_command.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################

Then('the acdoor player should see {string}') do |fragment|
  match = @acdoor_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@acdoor_player.messages.inspect}")
end

Then('the acdoor room should have received out_event') do
  assert(!@acdoor_room.events.empty?,
    "Expected room.out_event to have been called but no events were recorded")
end
