# frozen_string_literal: true
###############################################################################
# Step definitions for AcroomCommand action coverage.                         #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/acroom'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AcroomWorld
  attr_accessor :acroom_player, :acroom_out_dir, :acroom_in_dir,
                :acroom_name, :acroom_created_objects, :acroom_room
end
World(AcroomWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AcroomPlayer
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

# Mock room that records output and has a container pointer.
class AcroomRoom
  attr_accessor :container, :goid, :name
  attr_reader :messages

  def initialize(goid, container: nil, name: "Test Room")
    @goid      = goid
    @container = container
    @name      = name
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end

  def to_s
    @name
  end

  def eql?(other)
    other.respond_to?(:goid) && other.goid == @goid
  end

  def ==(other)
    eql?(other)
  end
end

# Mock area double with map_type, position, and find_by_position.
class AcroomArea
  attr_accessor :map_type, :goid

  def initialize(map_type: :rooms, goid: "area_goid_1")
    @map_type    = map_type
    @goid        = goid
    @positions   = {}  # { room_goid => [x, y] }
    @pos_to_room = {}  # { "x,y" => room }
  end

  def register_room(room, pos)
    @positions[room.goid] = pos
    @pos_to_room[pos_key(pos)] = room
  end

  def position(room)
    @positions[room.goid] || [0, 0]
  end

  def find_by_position(pos)
    @pos_to_room[pos_key(pos)]
  end

  private

  def pos_key(pos)
    "#{pos[0]},#{pos[1]}"
  end
end

# Mock exit double (result of create_object for Exit).
class AcroomExit
  attr_accessor :goid, :alt_names

  def initialize(goid, alt_names: [])
    @goid      = goid
    @alt_names = alt_names
  end

  def to_s
    "Exit<#{@alt_names.join(', ')}>"
  end
end

# Mock new room double (result of create_object for Room).
class AcroomNewRoom
  attr_accessor :goid, :name

  def initialize(goid, name: "New Room")
    @goid = goid
    @name = name
  end

  def to_s
    @name
  end
end

###############################################################################
# Ensure Room and Exit constants are available for the production code.       #
# These are used as class arguments to $manager.create_object and need to be  #
# resolvable in the scope of AcroomCommand#action.                            #
###############################################################################
unless defined?(::Room)
  Room = Class.new
end

unless defined?(::Exit)
  Exit = Class.new
end

###############################################################################
# Helper: build_acroom_manager                                                #
# Creates a stub $manager appropriate for the given area configuration.       #
###############################################################################
def build_acroom_manager(player:, room:, area:, collision_room: nil)
  created_objects = []
  create_counter = [0]

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player.container
      room
    elsif area && goid == room.container
      area
    else
      nil
    end
  end

  mgr.define_singleton_method(:create_object) do |klass, *args|
    create_counter[0] += 1
    if klass == Room || klass.to_s == "Room"
      # create_object(Room, area, new_pos, nil, :@name => name)
      obj = AcroomNewRoom.new("new_room_goid_#{create_counter[0]}", name: "NewRoom#{create_counter[0]}")
      created_objects << obj
      obj
    else
      # create_object(Exit, room, nil, target_goid, :@alt_names => [dir])
      # Extract alt_names from the vars hash if present
      vars = args.last.is_a?(Hash) ? args.last : {}
      alt_names_val = vars[:@alt_names] || []
      obj = AcroomExit.new("exit_goid_#{create_counter[0]}", alt_names: alt_names_val)
      created_objects << obj
      obj
    end
  end

  # Store collision room for find_by_position if area supports it
  if area && collision_room
    # Override the area's find_by_position to return collision room
    original_find = area.method(:find_by_position)
    area.define_singleton_method(:find_by_position) do |pos|
      result = original_find.call(pos)
      result || collision_room
    end
  end

  $manager = mgr
  created_objects
end

###############################################################################
# Given steps                                                                 #
###############################################################################

Given('a stubbed AcroomCommand environment with no area') do
  # Ensure `log` is available
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  @acroom_player = AcroomPlayer.new
  @acroom_room = AcroomRoom.new("room_goid_1", container: nil, name: "Origin Room")
  @acroom_player.container = @acroom_room.goid

  @acroom_created_objects = build_acroom_manager(
    player: @acroom_player, room: @acroom_room, area: nil
  )
end

Given('a stubbed AcroomCommand environment with area map_type none') do
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  @acroom_player = AcroomPlayer.new
  area = AcroomArea.new(map_type: :none)
  @acroom_room = AcroomRoom.new("room_goid_1", container: area.goid, name: "Origin Room")
  @acroom_player.container = @acroom_room.goid

  @acroom_created_objects = build_acroom_manager(
    player: @acroom_player, room: @acroom_room, area: area
  )
end

Given('a stubbed AcroomCommand environment with area map_type rooms') do
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  @acroom_player = AcroomPlayer.new
  area = AcroomArea.new(map_type: :rooms)
  @acroom_room = AcroomRoom.new("room_goid_1", container: area.goid, name: "Origin Room")
  area.register_room(@acroom_room, [0, 0])
  @acroom_player.container = @acroom_room.goid

  @acroom_created_objects = build_acroom_manager(
    player: @acroom_player, room: @acroom_room, area: area
  )
end

Given('a stubbed AcroomCommand environment with area map_type rooms and position collision') do
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  @acroom_player = AcroomPlayer.new
  area = AcroomArea.new(map_type: :rooms)
  @acroom_room = AcroomRoom.new("room_goid_1", container: area.goid, name: "Origin Room")
  area.register_room(@acroom_room, [0, 0])

  # Register a room at [0, 1] to cause collision when going north
  blocker = AcroomRoom.new("blocker_goid", name: "Blocking Room")
  area.register_room(blocker, [0, 1])

  @acroom_player.container = @acroom_room.goid

  @acroom_created_objects = build_acroom_manager(
    player: @acroom_player, room: @acroom_room, area: area
  )
end

Given('a stubbed AcroomCommand environment with world map and west neighbor') do
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  @acroom_player = AcroomPlayer.new
  area = AcroomArea.new(map_type: :world)
  @acroom_room = AcroomRoom.new("room_goid_1", container: area.goid, name: "Origin Room")
  area.register_room(@acroom_room, [0, 0])

  # When going north, new_pos = [0, 1]
  # west of new_pos = [-1, 1] - place a room there that's NOT the current room
  west_neighbor = AcroomRoom.new("west_neighbor_goid", name: "West Neighbor")
  area.register_room(west_neighbor, [-1, 1])

  @acroom_player.container = @acroom_room.goid

  @acroom_created_objects = build_acroom_manager(
    player: @acroom_player, room: @acroom_room, area: area
  )
end

Given('a stubbed AcroomCommand environment with world map and east neighbor') do
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  @acroom_player = AcroomPlayer.new
  area = AcroomArea.new(map_type: :world)
  @acroom_room = AcroomRoom.new("room_goid_1", container: area.goid, name: "Origin Room")
  area.register_room(@acroom_room, [0, 0])

  # When going north, new_pos = [0, 1]
  # east of new_pos = [1, 1] - place a room there, NO west neighbor
  east_neighbor = AcroomRoom.new("east_neighbor_goid", name: "East Neighbor")
  area.register_room(east_neighbor, [1, 1])

  @acroom_player.container = @acroom_room.goid

  @acroom_created_objects = build_acroom_manager(
    player: @acroom_player, room: @acroom_room, area: area
  )
end

Given('a stubbed AcroomCommand environment with world map and north neighbor') do
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  @acroom_player = AcroomPlayer.new
  area = AcroomArea.new(map_type: :world)
  @acroom_room = AcroomRoom.new("room_goid_1", container: area.goid, name: "Origin Room")
  area.register_room(@acroom_room, [0, 0])

  # When going east, new_pos = [1, 0]
  # north of new_pos = [1, 1] - place a room there, NO west or east neighbor
  # west of new_pos = [0, 0] but that IS the current room, so it's skipped
  # east of new_pos = [2, 0] - no room there
  north_neighbor = AcroomRoom.new("north_neighbor_goid", name: "North Neighbor")
  area.register_room(north_neighbor, [1, 1])

  @acroom_player.container = @acroom_room.goid

  @acroom_created_objects = build_acroom_manager(
    player: @acroom_player, room: @acroom_room, area: area
  )
end

Given('a stubbed AcroomCommand environment with world map and south neighbor') do
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  @acroom_player = AcroomPlayer.new
  area = AcroomArea.new(map_type: :world)
  @acroom_room = AcroomRoom.new("room_goid_1", container: area.goid, name: "Origin Room")
  area.register_room(@acroom_room, [0, 0])

  # When going east, new_pos = [1, 0]
  # west of new_pos = [0, 0] which IS the current room => skipped
  # east of new_pos = [2, 0] - no room
  # north of new_pos = [1, 1] - no room
  # south of new_pos = [1, -1] - place a room here
  south_neighbor = AcroomRoom.new("south_neighbor_goid", name: "South Neighbor")
  area.register_room(south_neighbor, [1, -1])

  @acroom_player.container = @acroom_room.goid

  @acroom_created_objects = build_acroom_manager(
    player: @acroom_player, room: @acroom_room, area: area
  )
end

Given('the acroom out direction is {string}') do |dir|
  @acroom_out_dir = dir
end

Given('the acroom in direction is {string}') do |dir|
  @acroom_in_dir = dir
end

Given('the acroom new room name is {string}') do |name|
  @acroom_name = name
end

###############################################################################
# When steps                                                                  #
###############################################################################

When('the AcroomCommand action is invoked') do
  data = {
    out_dir: @acroom_out_dir,
    in_dir:  @acroom_in_dir,
    name:    @acroom_name
  }

  cmd = Aethyr::Core::Actions::Acroom::AcroomCommand.new(@acroom_player, **data)
  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################

Then('the acroom player should see {string}') do |fragment|
  match = @acroom_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected player output containing #{fragment.inspect}, got: #{@acroom_player.messages.inspect}")
end

Then('the acroom player should not see {string}') do |fragment|
  match = @acroom_player.messages.any? { |m| m.include?(fragment) }
  assert(!match,
    "Expected player output NOT containing #{fragment.inspect}, got: #{@acroom_player.messages.inspect}")
end

Then('the acroom created objects count should be at least {int}') do |count|
  assert(@acroom_created_objects.length >= count,
    "Expected at least #{count} created objects, got #{@acroom_created_objects.length}: #{@acroom_created_objects.inspect}")
end

Then('the acroom room should see {string}') do |fragment|
  match = @acroom_room.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected room output containing #{fragment.inspect}, got: #{@acroom_room.messages.inspect}")
end
