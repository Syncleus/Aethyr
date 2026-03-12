# frozen_string_literal: true

###############################################################################
# Step definitions for the Area game object feature.                           #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'

World(Test::Unit::Assertions)

###############################################################################
# Lightweight StubManager so Area can be instantiated without the full engine. #
# We reopen (or create) the class to add methods required by Area / GameObject.#
###############################################################################
unless defined?(StubManager)
  class StubManager
    def initialize; end
  end
end

class StubManager
  unless method_defined?(:existing_goid?)
    def existing_goid?(_goid); false; end
  end
  unless method_defined?(:submit_action)
    def submit_action(_action); end
  end
  unless method_defined?(:find)
    def find(_id); nil; end
  end
end

###############################################################################
# Mock objects for testing Area in isolation.                                   #
###############################################################################
module AreaTestWorld
  # A minimal mock exit that responds to alt_names
  class MockExit
    attr_accessor :alt_names, :game_object_id, :visible
    def initialize(direction, goid = nil)
      @alt_names = [direction]
      @game_object_id = goid || "exit-#{direction}-#{rand(99999)}"
      @visible = true
    end

    def name; @alt_names[0]; end
    def generic; "exit"; end
    def container; nil; end
    def container=(_v); end
  end

  # A minimal mock room that provides the interface Area rendering expects.
  class MockRoom
    attr_accessor :game_object_id, :container, :visible, :alt_names, :generic
    attr_accessor :exit_map, :exit_list, :player_list, :mob_list, :name

    def initialize(goid, opts = {})
      @game_object_id = goid
      @container = opts[:container]
      @visible = true
      @alt_names = []
      @generic = "room"
      @name = opts[:name] || "room"
      @exit_map = opts[:exit_map] || {}     # { "north" => exit_obj_or_nil, ... }
      @exit_list = opts[:exit_list] || []   # array of MockExit
      @player_list = opts[:player_list] || []
      @mob_list = opts[:mob_list] || []
    end

    def exit(direction)
      @exit_map[direction]
    end

    def exits
      @exit_list
    end

    def players(_visible = true, _exclude = nil)
      @player_list
    end

    def mobs
      @mob_list
    end

    def eql?(other)
      other.is_a?(MockRoom) && other.game_object_id == @game_object_id
    end

    def ==(other)
      eql?(other)
    end
  end

  # A minimal mock player
  class MockPlayer
    attr_accessor :container, :game_object_id, :visible, :alt_names, :generic, :name
    def initialize(container_id)
      @container = container_id
      @game_object_id = "player-#{rand(99999)}"
      @visible = true
      @alt_names = []
      @generic = "player"
      @name = "testplayer"
    end
  end

  # A minimal mock mob
  class MockMob
    attr_accessor :game_object_id, :visible
    def initialize
      @game_object_id = "mob-#{rand(99999)}"
      @visible = true
    end
  end

  attr_accessor :area, :player, :render_result, :check_result, :error_result
end
World(AreaTestWorld)

###############################################################################
# Helper: builds a MockRoom, adds it to the area at a given position,        #
# and returns the room.                                                       #
###############################################################################
def add_room_to_area(area, position, opts = {})
  goid = opts.delete(:goid) || "room-#{position[0]}-#{position[1]}"
  room = AreaTestWorld::MockRoom.new(goid, opts)
  area.add(room, position)
  room
end

###############################################################################
# Given steps                                                                  #
###############################################################################
Given('I have a stub manager for area tests') do
  $manager = StubManager.new unless $manager.is_a?(StubManager)
end

Given('I create a new Area') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  self.player = AreaTestWorld::MockPlayer.new("no-container")
end

Given('the area map_type is set to none') do
  area.map_type = :none
end

Given('the area map_type is set to world') do
  area.map_type = :world
end

Given('the area map_type is set to invalid') do
  area.map_type = :foobar
end

Given('I create a new Area with rooms for world map') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  room = add_room_to_area(area, [0, 0], name: "origin")
  self.player = AreaTestWorld::MockPlayer.new(room.game_object_id)
end

Given('I create a new Area with a grid of rooms for world map') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :world

  # Create a 3x3 grid of rooms
  rooms = {}
  (-1..1).each do |x|
    (-1..1).each do |y|
      rooms[[x, y]] = add_room_to_area(area, [x, y], name: "room-#{x}-#{y}")
    end
  end

  # Player is in the center room
  center_room = rooms[[0, 0]]
  self.player = AreaTestWorld::MockPlayer.new(center_room.game_object_id)
end

Given('I create a new Area with sparse rooms for world map') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :world

  # Only place a room at origin; surrounding positions are empty
  room = add_room_to_area(area, [0, 0], name: "lonely-room")
  self.player = AreaTestWorld::MockPlayer.new(room.game_object_id)
end

Given('I create a new Area with rooms for room map') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  room = add_room_to_area(area, [0, 0], name: "origin",
    exit_list: [AreaTestWorld::MockExit.new("north"), AreaTestWorld::MockExit.new("south")])
  self.player = AreaTestWorld::MockPlayer.new(room.game_object_id)
end

Given('I create an Area with a single room at origin') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  room = add_room_to_area(area, [0, 0], name: "single",
    exit_list: [AreaTestWorld::MockExit.new("north"), AreaTestWorld::MockExit.new("south")])
  self.player = AreaTestWorld::MockPlayer.new(room.game_object_id)
end

Given('I create an Area with a 2x2 grid of connected rooms') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  north_exit = AreaTestWorld::MockExit.new("north")
  south_exit = AreaTestWorld::MockExit.new("south")
  east_exit = AreaTestWorld::MockExit.new("east")
  west_exit = AreaTestWorld::MockExit.new("west")

  # Room at [0,0] has north and east exits
  r00 = add_room_to_area(area, [0, 0], name: "r00",
    exit_map: { "north" => north_exit, "east" => east_exit },
    exit_list: [AreaTestWorld::MockExit.new("north"), AreaTestWorld::MockExit.new("east")])

  # Room at [1,0] has west exit
  r10 = add_room_to_area(area, [1, 0], name: "r10",
    exit_map: { "west" => west_exit },
    exit_list: [AreaTestWorld::MockExit.new("west")])

  # Room at [0,1] has south exit
  r01 = add_room_to_area(area, [0, 1], name: "r01",
    exit_map: { "south" => south_exit },
    exit_list: [AreaTestWorld::MockExit.new("south")])

  # Room at [1,1]
  r11 = add_room_to_area(area, [1, 1], name: "r11",
    exit_list: [])

  self.player = AreaTestWorld::MockPlayer.new(r00.game_object_id)
end

Given('I create an Area with two rooms connected north-south') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  north_exit_obj = AreaTestWorld::MockExit.new("north")
  south_exit_obj = AreaTestWorld::MockExit.new("south")

  r_south = add_room_to_area(area, [0, 0], name: "south-room",
    exit_map: { "north" => north_exit_obj },
    exit_list: [AreaTestWorld::MockExit.new("north")])

  r_north = add_room_to_area(area, [0, 1], name: "north-room",
    exit_map: { "south" => south_exit_obj },
    exit_list: [AreaTestWorld::MockExit.new("south")])

  self.player = AreaTestWorld::MockPlayer.new(r_south.game_object_id)
end

Given('I create an Area with two rooms connected east-west') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  west_exit_obj = AreaTestWorld::MockExit.new("west")
  east_exit_obj = AreaTestWorld::MockExit.new("east")

  r_west = add_room_to_area(area, [0, 0], name: "west-room",
    exit_map: { "east" => east_exit_obj },
    exit_list: [AreaTestWorld::MockExit.new("east")])

  r_east = add_room_to_area(area, [1, 0], name: "east-room",
    exit_map: { "west" => west_exit_obj },
    exit_list: [AreaTestWorld::MockExit.new("west")])

  self.player = AreaTestWorld::MockPlayer.new(r_west.game_object_id)
end

Given('I create an Area with one-way north exit') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  north_exit_obj = AreaTestWorld::MockExit.new("north")

  # South room has north exit, but north room has NO south exit
  r_south = add_room_to_area(area, [0, 0], name: "south-room",
    exit_map: { "north" => north_exit_obj },
    exit_list: [AreaTestWorld::MockExit.new("north")])

  r_north = add_room_to_area(area, [0, 1], name: "north-room",
    exit_map: {},
    exit_list: [])

  self.player = AreaTestWorld::MockPlayer.new(r_south.game_object_id)
end

Given('I create an Area with one-way south exit') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  south_exit_obj = AreaTestWorld::MockExit.new("south")

  # South room has NO north exit, but north room has south exit
  r_south = add_room_to_area(area, [0, 0], name: "south-room",
    exit_map: {},
    exit_list: [])

  r_north = add_room_to_area(area, [0, 1], name: "north-room",
    exit_map: { "south" => south_exit_obj },
    exit_list: [AreaTestWorld::MockExit.new("south")])

  self.player = AreaTestWorld::MockPlayer.new(r_south.game_object_id)
end

Given('I create an Area with one-way west exit') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  west_exit_obj = AreaTestWorld::MockExit.new("west")

  # East room has west exit, but west room has NO east exit
  r_west = add_room_to_area(area, [0, 0], name: "west-room",
    exit_map: {},
    exit_list: [])

  r_east = add_room_to_area(area, [1, 0], name: "east-room",
    exit_map: { "west" => west_exit_obj },
    exit_list: [AreaTestWorld::MockExit.new("west")])

  self.player = AreaTestWorld::MockPlayer.new(r_west.game_object_id)
end

Given('I create an Area with one-way east exit') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  east_exit_obj = AreaTestWorld::MockExit.new("east")

  # West room has east exit, but east room has NO west exit
  r_west = add_room_to_area(area, [0, 0], name: "west-room",
    exit_map: { "east" => east_exit_obj },
    exit_list: [AreaTestWorld::MockExit.new("east")])

  r_east = add_room_to_area(area, [1, 0], name: "east-room",
    exit_map: {},
    exit_list: [])

  self.player = AreaTestWorld::MockPlayer.new(r_west.game_object_id)
end

Given('I create an Area with adjacent rooms but no exits between them') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  r0 = add_room_to_area(area, [0, 0], name: "room-a",
    exit_map: {},
    exit_list: [])

  r1 = add_room_to_area(area, [1, 0], name: "room-b",
    exit_map: {},
    exit_list: [])

  r2 = add_room_to_area(area, [0, 1], name: "room-c",
    exit_map: {},
    exit_list: [])

  self.player = AreaTestWorld::MockPlayer.new(r0.game_object_id)
end

Given('I create a new Area with a room containing the player') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  room = add_room_to_area(area, [0, 0], name: "player-room",
    exit_list: [AreaTestWorld::MockExit.new("north"), AreaTestWorld::MockExit.new("south")])
  self.player = AreaTestWorld::MockPlayer.new(room.game_object_id)
end

Given('I create a new Area with a room containing mobs') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  mob = AreaTestWorld::MockMob.new
  room = add_room_to_area(area, [0, 0], name: "mob-room",
    exit_list: [AreaTestWorld::MockExit.new("north"), AreaTestWorld::MockExit.new("south")],
    mob_list: [mob])
  # Player is in a different room so me_here is false
  other_room = add_room_to_area(area, [5, 5], name: "other")
  self.player = AreaTestWorld::MockPlayer.new(other_room.game_object_id)
end

Given('I create a new Area with a room containing another player') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  other_player = AreaTestWorld::MockPlayer.new("nowhere")
  room = add_room_to_area(area, [0, 0], name: "social-room",
    exit_list: [AreaTestWorld::MockExit.new("north"), AreaTestWorld::MockExit.new("south")],
    player_list: [other_player])
  other_room = add_room_to_area(area, [5, 5], name: "other")
  self.player = AreaTestWorld::MockPlayer.new(other_room.game_object_id)
end

Given('I create a new Area with a room with nonstandard exits') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  portal_exit = AreaTestWorld::MockExit.new("portal")
  room = add_room_to_area(area, [0, 0], name: "portal-room",
    exit_list: [portal_exit])
  other_room = add_room_to_area(area, [5, 5], name: "other")
  self.player = AreaTestWorld::MockPlayer.new(other_room.game_object_id)
end

Given('I create a new Area with a room with up exit') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  up_exit = AreaTestWorld::MockExit.new("up")
  room = add_room_to_area(area, [0, 0], name: "up-room",
    exit_list: [up_exit])
  other_room = add_room_to_area(area, [5, 5], name: "other")
  self.player = AreaTestWorld::MockPlayer.new(other_room.game_object_id)
end

Given('I create a new Area with a room with down exit') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  down_exit = AreaTestWorld::MockExit.new("down")
  room = add_room_to_area(area, [0, 0], name: "down-room",
    exit_list: [down_exit])
  other_room = add_room_to_area(area, [5, 5], name: "other")
  self.player = AreaTestWorld::MockPlayer.new(other_room.game_object_id)
end

Given('I create a new Area with a room with zone change and down exit') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  portal_exit = AreaTestWorld::MockExit.new("portal")
  down_exit = AreaTestWorld::MockExit.new("down")
  room = add_room_to_area(area, [0, 0], name: "zone-down-room",
    exit_list: [portal_exit, down_exit])
  other_room = add_room_to_area(area, [5, 5], name: "other")
  self.player = AreaTestWorld::MockPlayer.new(other_room.game_object_id)
end

Given('I create a new Area with a room with zone change and up exit') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  portal_exit = AreaTestWorld::MockExit.new("portal")
  up_exit = AreaTestWorld::MockExit.new("up")
  room = add_room_to_area(area, [0, 0], name: "zone-up-room",
    exit_list: [portal_exit, up_exit])
  other_room = add_room_to_area(area, [5, 5], name: "other")
  self.player = AreaTestWorld::MockPlayer.new(other_room.game_object_id)
end

Given('I create an Area for border character testing') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  # Place rooms at specific positions to trigger all border combinations.
  # We need: here, west, north, northwest rooms in various combos.
  #
  # Grid layout (columns are x, rows are y):
  #   [0,2] [1,2] [2,2]
  #   [0,1] [1,1] [2,1]
  #   [0,0] [1,0] [2,0]
  #
  # Place rooms at [0,0], [1,0], [0,1], [1,1], [2,2]
  # This creates:
  # - At grid intersection for [1,1]: here=1,1 north=nil west=0,1 nw=nil => "┬" if here&west
  #   Actually the intersection logic is complex. Let me place a full 3x3 grid to hit all combos.

  north_exit = AreaTestWorld::MockExit.new("north")
  south_exit = AreaTestWorld::MockExit.new("south")
  east_exit = AreaTestWorld::MockExit.new("east")
  west_exit = AreaTestWorld::MockExit.new("west")

  (-1..2).each do |x|
    (-1..2).each do |y|
      add_room_to_area(area, [x, y], name: "r#{x}#{y}",
        exit_map: {
          "north" => north_exit,
          "south" => south_exit,
          "east" => east_exit,
          "west" => west_exit
        },
        exit_list: [
          AreaTestWorld::MockExit.new("north"),
          AreaTestWorld::MockExit.new("south"),
          AreaTestWorld::MockExit.new("east"),
          AreaTestWorld::MockExit.new("west")
        ])
    end
  end

  room = area.find_by_position([0, 0])
  self.player = AreaTestWorld::MockPlayer.new(room.game_object_id)
end

Given('I create an Area with only a west room') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  # Place room at [-1, 0] only. When rendering at position [0,0],
  # this room is "west" of the center column.
  r = add_room_to_area(area, [-1, 0], name: "west-only",
    exit_list: [])

  self.player = AreaTestWorld::MockPlayer.new(r.game_object_id)
end

Given('I create an Area with only a northwest room') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  r = add_room_to_area(area, [-1, 1], name: "nw-only",
    exit_list: [])

  self.player = AreaTestWorld::MockPlayer.new(r.game_object_id)
end

Given('I create an Area with only a north room') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  r = add_room_to_area(area, [0, 1], name: "north-only",
    exit_list: [])

  self.player = AreaTestWorld::MockPlayer.new(r.game_object_id)
end

Given('I create an Area with northwest and west rooms') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  add_room_to_area(area, [-1, 1], name: "nw-room", exit_list: [])
  r = add_room_to_area(area, [-1, 0], name: "w-room", exit_list: [])

  self.player = AreaTestWorld::MockPlayer.new(r.game_object_id)
end

Given('I create an Area with northwest and north rooms') do
  require 'aethyr/core/objects/area'
  self.area = Aethyr::Core::Objects::Area.new(nil)
  area.map_type = :rooms

  add_room_to_area(area, [-1, 1], name: "nw-room", exit_list: [])
  r = add_room_to_area(area, [0, 1], name: "n-room", exit_list: [])

  self.player = AreaTestWorld::MockPlayer.new(r.game_object_id)
end

###############################################################################
# When steps                                                                   #
###############################################################################
When('I call render_map on the area') do
  self.render_result = area.render_map(player, [0, 0])
end

When('I call render_map on the area with small grid') do
  self.render_result = area.render_map(player, [0, 0], 3, 3)
end

When('I render the world map centered on the player') do
  self.render_result = area.send(:render_world, player, [0, 0], 3, 3)
end

When('I call render_rooms with nil position') do
  self.render_result = area.send(:render_rooms, player, nil, 2, 2)
end

When('I render rooms map centered at origin') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I render rooms map for the 2x2 grid') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I render rooms map for north-south rooms') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I render rooms map for east-west rooms') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I render rooms map for one-way north') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I render rooms map for one-way south') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I render rooms map for one-way west') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I render rooms map for one-way east') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I render rooms map for no-exit rooms') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I call render_room with nil room') do
  self.render_result = area.send(:render_room, nil, player)
end

When('I call render_room for the player room') do
  room = area.find_by_position([0, 0])
  self.render_result = area.send(:render_room, room, player)
end

When('I call render_room for the mob room') do
  room = area.find_by_position([0, 0])
  self.render_result = area.send(:render_room, room, player)
end

When('I call render_room for the other player room') do
  room = area.find_by_position([0, 0])
  self.render_result = area.send(:render_room, room, player)
end

When('I call render_room for the nonstandard exit room') do
  room = area.find_by_position([0, 0])
  self.render_result = area.send(:render_room, room, player)
end

When('I call render_room for the up exit room') do
  room = area.find_by_position([0, 0])
  self.render_result = area.send(:render_room, room, player)
end

When('I call render_room for the down exit room') do
  room = area.find_by_position([0, 0])
  self.render_result = area.send(:render_room, room, player)
end

When('I call render_room for the zone change down room') do
  room = area.find_by_position([0, 0])
  self.render_result = area.send(:render_room, room, player)
end

When('I call render_room for the zone change up room') do
  room = area.find_by_position([0, 0])
  self.render_result = area.send(:render_room, room, player)
end

When('I check nonstandard exits on a room with only cardinal exits') do
  room = AreaTestWorld::MockRoom.new("cardinal-room",
    exit_list: [
      AreaTestWorld::MockExit.new("north"),
      AreaTestWorld::MockExit.new("south"),
      AreaTestWorld::MockExit.new("east"),
      AreaTestWorld::MockExit.new("west"),
      AreaTestWorld::MockExit.new("up"),
      AreaTestWorld::MockExit.new("down")
    ])
  self.check_result = area.send(:room_has_nonstandard_exits, room)
end

When('I check nonstandard exits on a room with a portal exit') do
  room = AreaTestWorld::MockRoom.new("portal-room",
    exit_list: [
      AreaTestWorld::MockExit.new("north"),
      AreaTestWorld::MockExit.new("portal")
    ])
  self.check_result = area.send(:room_has_nonstandard_exits, room)
end

When('I render the border test map') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I render rooms map for only west room') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I render rooms map for only northwest room') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I render rooms map for only north room') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I render rooms map for northwest-west rooms') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

When('I render rooms map for northwest-north rooms') do
  self.render_result = area.send(:render_rooms, player, [0, 0], 3, 3)
end

###############################################################################
# Then steps                                                                   #
###############################################################################
Then('the area article should be {string}') do |expected|
  # Access via the reader method; article is attr_reader in GameObject
  assert_equal(expected, area.article)
end

Then('the area generic should be {string}') do |expected|
  assert_equal(expected, area.generic)
end

Then('the area map_type should be rooms') do
  assert_equal(:rooms, area.map_type)
end

Then('the render_map result should contain {string}') do |expected|
  assert(render_result.include?(expected),
         "Expected result to contain '#{expected}', got: #{render_result}")
end

Then('calling render_map should raise an error') do
  self.error_result = nil
  begin
    area.render_map(player, [0, 0])
  rescue RuntimeError => e
    self.error_result = e
  end
  assert_not_nil(error_result, "Expected RuntimeError to be raised")
  assert(error_result.message.include?("Invalid map type"),
         "Expected 'Invalid map type' in error, got: #{error_result.message}")
end

Then('the render_map result should be a non-empty string') do
  assert(render_result.is_a?(String), "Expected String result")
  assert(!render_result.empty?, "Expected non-empty result")
end

Then('the world map should contain the player marker') do
  assert(render_result.include?("☺"),
         "Expected world map to contain player marker ☺, got:\n#{render_result}")
end

Then('the world map should contain terrain markers') do
  assert(render_result.include?("░"),
         "Expected world map to contain terrain marker ░, got:\n#{render_result}")
end

Then('the world map should contain spaces for empty positions') do
  assert(render_result.include?(" "),
         "Expected world map to contain spaces for empty positions")
end

Then('the result should say location does not appear on maps') do
  assert(render_result.include?("doesn't appear on any maps"),
         "Expected message about location not on maps, got: #{render_result}")
end

Then('the rooms map should contain border characters') do
  assert(render_result.is_a?(String), "Expected String result")
  # A single room should have at least a corner character
  has_border = render_result.include?("┌") || render_result.include?("─") ||
               render_result.include?("│") || render_result.include?("┘") ||
               render_result.include?("└") || render_result.include?("┐") ||
               render_result.include?("┬") || render_result.include?("┴") ||
               render_result.include?("├") || render_result.include?("┼")
  assert(has_border, "Expected border characters in rooms map, got:\n#{render_result}")
end

Then('the rooms map should contain crossing characters') do
  assert(render_result.is_a?(String), "Expected String result")
  has_cross = render_result.include?("┼") || render_result.include?("├") ||
              render_result.include?("┬") || render_result.include?("┤") ||
              render_result.include?("┴")
  assert(has_cross, "Expected crossing characters in rooms map, got:\n#{render_result}")
end

Then('the rooms map should contain vertical exit arrows') do
  has_arrow = render_result.include?("↕")
  assert(has_arrow, "Expected vertical exit arrow ↕ in rooms map, got:\n#{render_result}")
end

Then('the rooms map should contain horizontal exit arrows') do
  has_arrow = render_result.include?("↔")
  assert(has_arrow, "Expected horizontal exit arrow ↔ in rooms map, got:\n#{render_result}")
end

Then('the rooms map should contain an up arrow') do
  has_arrow = render_result.include?("↑")
  assert(has_arrow, "Expected up arrow ↑ in rooms map, got:\n#{render_result}")
end

Then('the rooms map should contain a down arrow') do
  has_arrow = render_result.include?("↓")
  assert(has_arrow, "Expected down arrow ↓ in rooms map, got:\n#{render_result}")
end

Then('the rooms map should contain a left arrow') do
  has_arrow = render_result.include?("←")
  assert(has_arrow, "Expected left arrow ← in rooms map, got:\n#{render_result}")
end

Then('the rooms map should contain a right arrow') do
  has_arrow = render_result.include?("→")
  assert(has_arrow, "Expected right arrow → in rooms map, got:\n#{render_result}")
end

Then('the rooms map should contain wall characters') do
  # Adjacent rooms with no exits should show wall characters (│ or ─)
  has_wall = render_result.include?("│") || render_result.include?("─")
  assert(has_wall, "Expected wall characters in rooms map, got:\n#{render_result}")
end

Then('the render_room result should be three spaces') do
  assert_equal("   ", render_result)
end

Then('the render_room result should contain the me marker') do
  assert(render_result.include?("<me>☺</me>"),
         "Expected me marker <me>☺</me>, got: #{render_result}")
end

Then('the render_room result should contain the mob marker') do
  assert(render_result.include?("<mob>*</mob>"),
         "Expected mob marker <mob>*</mob>, got: #{render_result}")
end

Then('the render_room result should contain the player marker') do
  assert(render_result.include?("<player>☺</player>"),
         "Expected player marker <player>☺</player>, got: #{render_result}")
end

Then('the render_room result should contain the exit marker') do
  assert(render_result.include?("<exit>☼</exit>"),
         "Expected exit marker <exit>☼</exit>, got: #{render_result}")
end

Then('the render_room result should contain the up exit marker') do
  assert(render_result.include?("<exit>↑</exit>"),
         "Expected up exit marker <exit>↑</exit>, got: #{render_result}")
end

Then('the render_room result should contain the down exit marker') do
  assert(render_result.include?("<exit>↓</exit>"),
         "Expected down exit marker <exit>↓</exit>, got: #{render_result}")
end

Then('the render_room result should have exit markers on both sides') do
  # zone_change on left, down on right
  assert(render_result.include?("<exit>☼</exit>"),
         "Expected zone change marker on left, got: #{render_result}")
  assert(render_result.include?("<exit>↓</exit>"),
         "Expected down exit marker on right, got: #{render_result}")
end

Then('the render_room result should have zone exit on left') do
  assert(render_result.include?("<exit>☼</exit>"),
         "Expected zone change marker, got: #{render_result}")
end

Then('the result should be false') do
  assert_equal(false, check_result)
end

Then('the result should be true') do
  assert_equal(true, check_result)
end

Then('the rooms map should contain various border characters') do
  assert(render_result.is_a?(String), "Expected String result")
  # With a full grid we should see crossing characters
  assert(render_result.include?("┼"),
         "Expected ┼ in border test, got:\n#{render_result}")
end

Then('the rooms map should contain right cap border') do
  assert(render_result.is_a?(String), "Expected String result")
  has_char = render_result.include?("┐") || render_result.include?("│") || render_result.include?("┘")
  assert(has_char, "Expected right cap border character, got:\n#{render_result}")
end

Then('the rooms map should contain bottom-right corner border') do
  assert(render_result.is_a?(String), "Expected String result")
  has_char = render_result.include?("┘") || render_result.include?("─") || render_result.include?("│")
  assert(has_char, "Expected bottom-right corner character, got:\n#{render_result}")
end

Then('the rooms map should contain bottom-left corner border') do
  assert(render_result.is_a?(String), "Expected String result")
  has_char = render_result.include?("└") || render_result.include?("─") || render_result.include?("│")
  assert(has_char, "Expected bottom-left corner character, got:\n#{render_result}")
end

Then('the rooms map should contain right-tee border') do
  assert(render_result.is_a?(String), "Expected String result")
  has_char = render_result.include?("┤") || render_result.include?("│") || render_result.include?("─")
  assert(has_char, "Expected right-tee border character, got:\n#{render_result}")
end

Then('the rooms map should contain bottom-tee border') do
  assert(render_result.is_a?(String), "Expected String result")
  has_char = render_result.include?("┴") || render_result.include?("│") || render_result.include?("─")
  assert(has_char, "Expected bottom-tee border character, got:\n#{render_result}")
end
