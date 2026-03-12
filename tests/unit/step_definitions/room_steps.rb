# frozen_string_literal: true
###############################################################################
# Step definitions for Room game object coverage.                              #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'

World(Test::Unit::Assertions)

###############################################################################
# Stub manager – must exist before Room (via GameObject) is instantiated.      #
###############################################################################
unless defined?(RoomStubManager)
  class RoomStubManager
    def existing_goid?(_goid); false; end
    def find(_id); nil; end
    def submit_action(_action); end
  end
end

###############################################################################
# Ensure ServerConfig exists (needed by some code paths in log / Guid).        #
###############################################################################
unless defined?(::ServerConfig)
  module ::ServerConfig
    @data = {}
    class << self
      def [](key);       @data[key]; end
      def []=(key, val); @data[key] = val; end
    end
  end
end

###############################################################################
# Set $manager *before* requiring Room so that Guid generation doesn't blow up.#
###############################################################################
$manager ||= RoomStubManager.new

###############################################################################
# Require the actual Room class (and its transitive dependencies).             #
###############################################################################
require 'aethyr/core/objects/room'
require 'aethyr/core/objects/exit'
require 'aethyr/core/objects/info/terrain'

###############################################################################
# World module – scenario-scoped state                                         #
###############################################################################
module RoomTestWorld
  attr_accessor :room_test_room, :room_test_player, :room_test_result,
                :room_test_added_object, :room_test_added_player,
                :room_test_added_mobile, :room_test_added_exit,
                :room_test_look_player
end
World(RoomTestWorld)

###############################################################################
# Lightweight doubles that satisfy is_a? checks used by Room.                  #
###############################################################################

# We do NOT define stub Player/Mobile classes here because they would
# conflict with the real ones when all step files are loaded together.
# Instead, our test doubles override is_a? to fool the Room's type checks.

###############################################################################
# Mock objects                                                                 #
###############################################################################

# Helper to resolve classes lazily for is_a? comparisons.
module RoomTestClassResolver
  def self.player_class
    Aethyr::Core::Objects::Player rescue nil
  end

  def self.mobile_class
    Aethyr::Core::Objects::Mobile rescue nil
  end

  def self.exit_class
    Aethyr::Core::Objects::Exit rescue nil
  end

  def self.top_mobile_class
    ::Mobile rescue nil
  end
end

# A generic item that goes into a room's inventory.
class RoomTestItem
  attr_accessor :game_object_id, :container, :name, :alt_names, :generic,
                :visible, :show_in_look, :quantity, :article, :short_desc,
                :pose
  alias :goid :game_object_id

  def initialize(opts = {})
    @game_object_id = opts[:goid] || "room_item_#{rand(99999)}"
    @name       = opts[:name] || "thing"
    @alt_names  = opts[:alt_names] || []
    @generic    = opts[:generic] || "thing"
    @visible    = opts.fetch(:visible, true)
    @show_in_look = opts[:show_in_look] || false
    @quantity   = opts[:quantity] || 1
    @article    = opts[:article] || "a"
    @short_desc = opts[:short_desc]
    @pose       = opts[:pose]
    @can_traits = opts[:can_traits] || {}
    @alive_val  = opts.fetch(:alive, false)
    @container  = nil
  end

  # Emulate GameObject's `can?` (aliased from `respond_to?` in real code).
  def can?(trait)
    @can_traits.key?(trait)
  end

  def alive; @alive_val; end
  def blind?; false; end

  def is_a?(klass)
    pc = RoomTestClassResolver.player_class
    return false if pc && klass == pc
    ec = RoomTestClassResolver.exit_class
    return false if ec && klass == ec
    mc = RoomTestClassResolver.mobile_class
    return false if mc && klass == mc
    tc = RoomTestClassResolver.top_mobile_class
    return false if tc && klass == tc
    super
  end
end

# A mock player that passes the is_a?(Aethyr::Core::Objects::Player) check.
class RoomTestPlayer < RoomTestItem
  attr_accessor :blind_flag

  def initialize(opts = {})
    super(opts)
    @blind_flag = opts.fetch(:blind, false)
  end

  def blind?; @blind_flag; end

  def is_a?(klass)
    pc = RoomTestClassResolver.player_class
    return true if pc && klass == pc
    super(klass)
  end

  def output(msg, *_args); end
end

# A mock mobile that passes the is_a?(Mobile) check.
class RoomTestMobile < RoomTestItem
  def initialize(opts = {})
    super(opts)
  end

  def is_a?(klass)
    mc = RoomTestClassResolver.mobile_class
    return true if mc && klass == mc
    tc = RoomTestClassResolver.top_mobile_class
    return true if tc && klass == tc
    super(klass)
  end
end

# A mock exit that passes is_a?(Exit) check.
class RoomTestExit < RoomTestItem
  attr_accessor :alt_names, :open_state, :has_open_trait

  def initialize(opts = {})
    super(opts)
    @alt_names = opts[:alt_names] || [opts[:direction] || "north"]
    @generic = "exit"
    @has_open_trait = opts.fetch(:has_open_trait, false)
    @open_state = opts.fetch(:open_state, nil) # :open, :closed, or nil
  end

  def is_a?(klass)
    ec = RoomTestClassResolver.exit_class
    return true if ec && klass == ec
    super(klass)
  end

  def can?(trait)
    return @has_open_trait if trait == :open
    super
  end

  def closed?
    @open_state == :closed
  end

  def open?
    @open_state == :open
  end
end

# A mock flag for the room's info.flags
class RoomTestFlag
  attr_reader :id, :affect_desc

  def initialize(id, affect_desc, visible_to_player: true)
    @id = id
    @affect_desc = affect_desc
    @visible = visible_to_player
  end

  def can_see?(_player)
    @visible
  end

  def negate_flags(_flags); end
end

###############################################################################
# Given steps                                                                  #
###############################################################################
Given('a stubbed Room test environment') do
  $manager = RoomStubManager.new

  # Ensure `log` is available as a no-op.
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Provide a minimal $LOG
  unless $LOG
    $LOG = Object.new
    $LOG.define_singleton_method(:add) { |*_args, **_kwargs| }
    $LOG.define_singleton_method(:dump) { }
  end
end

###############################################################################
# When steps                                                                   #
###############################################################################
When('I create a new Room for room tests') do
  @room_test_room = Aethyr::Core::Objects::Room.new
end

When('I create a new Room for room tests with name {string} and desc {string}') do |name, desc|
  @room_test_room = Aethyr::Core::Objects::Room.new(nil, name)
  @room_test_room.instance_variable_set(:@short_desc, desc)
  @room_test_room.instance_variable_set(:@name, name)
end

When('I set the room indoors flag to true') do
  @room_test_room.info.indoors = true
end

When('I add a regular object to the room') do
  @room_test_added_object = RoomTestItem.new(name: "rock", generic: "rock", goid: "room_rock_1")
  @room_test_room.add(@room_test_added_object)
end

When('I add a room-test player to the room') do
  @room_test_added_player = RoomTestPlayer.new(name: "Hero", goid: "room_player_1")
  @room_test_room.add(@room_test_added_player)
end

When('I add a room-test mobile to the room') do
  @room_test_added_mobile = RoomTestMobile.new(name: "Goblin", goid: "room_mob_1")
  @room_test_room.add(@room_test_added_mobile)
end

When('I add an exit going {string} to the room') do |direction|
  @room_test_added_exit = RoomTestExit.new(
    direction: direction,
    alt_names: [direction],
    goid: "room_exit_#{direction}",
    name: direction
  )
  @room_test_room.add(@room_test_added_exit)
end

When('I populate the room with players and non-players') do
  visible_player = RoomTestPlayer.new(name: "Alice", goid: "rtp_alice", visible: true)
  non_player = RoomTestItem.new(name: "rock", goid: "rtp_rock")
  @room_test_room.add(visible_player)
  @room_test_room.add(non_player)
  @room_test_visible_player = visible_player
end

When('I populate the room with visible and invisible players') do
  visible_player = RoomTestPlayer.new(name: "Alice", goid: "rtp_vis", visible: true)
  invisible_player = RoomTestPlayer.new(name: "Bob", goid: "rtp_invis", visible: false)
  @room_test_room.add(visible_player)
  @room_test_room.add(invisible_player)
  @room_test_invisible_player = invisible_player
end

When('I populate the room with mobiles and players') do
  mob = RoomTestItem.new(
    name: "Rat", goid: "rtp_rat", visible: true,
    can_traits: { alive: true }, alive: true
  )
  player = RoomTestPlayer.new(name: "Hero", goid: "rtp_hero_mob", visible: true)
  @room_test_room.add(mob)
  @room_test_room.add(player)
  @room_test_mob = mob
end

When('I populate the room with things and exits') do
  thing = RoomTestItem.new(
    name: "Sword", goid: "rtp_sword", visible: true,
    can_traits: {}, alive: false
  )
  exit_obj = RoomTestExit.new(direction: "north", goid: "rtp_exit_n")
  @room_test_room.add(thing)
  @room_test_room.add(exit_obj)
  @room_test_thing = thing
end

When('I populate the room with exits and non-exits') do
  exit1 = RoomTestExit.new(direction: "north", goid: "rtp_exit1", visible: true)
  exit2 = RoomTestExit.new(direction: "south", goid: "rtp_exit2", visible: true)
  thing = RoomTestItem.new(name: "Chair", goid: "rtp_chair", visible: true)
  @room_test_room.add(exit1)
  @room_test_room.add(exit2)
  @room_test_room.add(thing)
end

When('I set up a blind player for look') do
  @room_test_look_player = RoomTestPlayer.new(name: "Blind", goid: "rtp_blind", blind: true)
end

When('I set up a sighted player for look') do
  @room_test_look_player = RoomTestPlayer.new(name: "Looker", goid: "rtp_looker", blind: false)
end

When('I set up room terrain and flags') do
  @room_test_room.info.terrain ||= Info.new
  @room_test_room.info.terrain.type = Terrain::CITY
  @room_test_room.info.flags ||= {}
end

When('I set up room terrain and flags with a visible flag') do
  @room_test_room.info.terrain ||= Info.new
  @room_test_room.info.terrain.type = Terrain::CITY
  flag = RoomTestFlag.new(:glow, "Glowing aura surrounds you", visible_to_player: true)
  @room_test_room.info.flags = { glow: flag }
end

When('I populate the room inventory for full look test') do
  # A player with pose
  p1 = RoomTestPlayer.new(
    name: "Alice", goid: "rtp_look_alice", visible: true,
    pose: "is meditating", short_desc: "a wise adventurer"
  )
  @room_test_room.add(p1)

  # A closed exit
  ex1 = RoomTestExit.new(
    direction: "north", goid: "rtp_look_exit_n", visible: true,
    has_open_trait: true, open_state: :closed
  )
  @room_test_room.add(ex1)

  # An open exit
  ex2 = RoomTestExit.new(
    direction: "east", goid: "rtp_look_exit_e", visible: true,
    has_open_trait: true, open_state: :open
  )
  @room_test_room.add(ex2)

  # A simple exit (no open trait)
  ex3 = RoomTestExit.new(
    direction: "south", goid: "rtp_look_exit_s", visible: true,
    has_open_trait: false
  )
  @room_test_room.add(ex3)

  # An alive mob
  mob1 = RoomTestItem.new(
    name: "Goblin", goid: "rtp_look_mob", visible: true, generic: "goblin",
    alt_names: ["creature"], can_traits: { alive: true }, alive: true
  )
  @room_test_room.add(mob1)

  # A thing with pose
  thing_posed = RoomTestItem.new(
    name: "Statue", goid: "rtp_look_statue", visible: true, generic: "statue",
    alt_names: ["figure"], can_traits: { pose: true }, alive: false,
    pose: "stands majestically", short_desc: "ancient stone"
  )
  @room_test_room.add(thing_posed)

  # A plain thing (no pose, not alive)
  thing_plain = RoomTestItem.new(
    name: "Coin", goid: "rtp_look_coin", visible: true, generic: "coin",
    alt_names: ["gold"], can_traits: {}, alive: false,
    short_desc: "shiny"
  )
  @room_test_room.add(thing_plain)

  # Item with show_in_look
  show_item = RoomTestItem.new(
    goid: "rtp_look_show", show_in_look: "A torch flickers on the wall."
  )
  @room_test_room.add(show_item)
end

When('I add an item with show_in_look text {string}') do |text|
  item = RoomTestItem.new(
    goid: "rtp_show_item_#{rand(99999)}", show_in_look: text, visible: false
  )
  @room_test_room.add(item)
end

When('I add a player with pose {string} to room inventory') do |pose|
  p = RoomTestPlayer.new(
    name: "Poser", goid: "rtp_poser_#{rand(99999)}", visible: true,
    pose: pose, short_desc: "a posed character"
  )
  @room_test_room.add(p)
end

When('I add a player without pose to room inventory') do
  p = RoomTestPlayer.new(
    name: "NoPose", goid: "rtp_nopose_#{rand(99999)}", visible: true,
    pose: nil, short_desc: nil
  )
  @room_test_room.add(p)
end

When('I add another player without pose to room inventory') do
  p = RoomTestPlayer.new(
    name: "AnotherPlayer", goid: "rtp_another_#{rand(99999)}", visible: true,
    pose: nil, short_desc: "another adventurer"
  )
  @room_test_room.add(p)
end

When('I add a closed exit {string} to room inventory') do |direction|
  ex = RoomTestExit.new(
    direction: direction, alt_names: [direction],
    goid: "rtp_closed_exit_#{direction}", visible: true,
    has_open_trait: true, open_state: :closed
  )
  @room_test_room.add(ex)
end

When('I add an open exit {string} to room inventory') do |direction|
  ex = RoomTestExit.new(
    direction: direction, alt_names: [direction],
    goid: "rtp_open_exit_#{direction}", visible: true,
    has_open_trait: true, open_state: :open
  )
  @room_test_room.add(ex)
end

When('I add a simple exit {string} to room inventory') do |direction|
  ex = RoomTestExit.new(
    direction: direction, alt_names: [direction],
    goid: "rtp_simple_exit_#{direction}", visible: true,
    has_open_trait: false
  )
  @room_test_room.add(ex)
end

When('I add an alive mob {string} to room inventory') do |name|
  mob = RoomTestItem.new(
    name: name, goid: "rtp_mob_#{name.downcase}_#{rand(99999)}", visible: true,
    generic: name.downcase, alt_names: [],
    can_traits: { alive: true }, alive: true
  )
  @room_test_room.add(mob)
end

When('I add a thing with pose {string} to room inventory') do |pose|
  thing = RoomTestItem.new(
    name: "Decorated Vase", goid: "rtp_posed_thing_#{rand(99999)}", visible: true,
    generic: "vase", alt_names: [],
    can_traits: { pose: true }, alive: false,
    pose: pose, short_desc: "ornate"
  )
  @room_test_room.add(thing)
end

When('I add a plain thing {string} to room inventory') do |name|
  thing = RoomTestItem.new(
    name: name, goid: "rtp_plain_#{rand(99999)}", visible: true,
    generic: name.downcase, alt_names: [],
    can_traits: {}, alive: false, short_desc: "rusty"
  )
  @room_test_room.add(thing)
end

When('I add a thing with quantity {int} to room inventory') do |qty|
  thing = RoomTestItem.new(
    name: "Arrow", goid: "rtp_qty_#{rand(99999)}", visible: true,
    generic: "arrow", alt_names: [],
    can_traits: {}, alive: false, quantity: qty, article: "an"
  )
  @room_test_room.add(thing)
end

###############################################################################
# Then steps                                                                   #
###############################################################################
Then('the room generic should be {string}') do |expected|
  assert_equal expected, @room_test_room.instance_variable_get(:@generic)
end

Then('the room should be indoors') do
  assert @room_test_room.indoors?, "Expected room to be indoors"
end

Then('the room inventory should contain that object') do
  found = @room_test_room.inventory.find(@room_test_added_object.game_object_id)
  assert_not_nil found, "Expected room inventory to contain the added object"
end

Then('the room inventory should contain that player') do
  found = @room_test_room.inventory.find(@room_test_added_player.game_object_id)
  assert_not_nil found, "Expected room inventory to contain the added player"
end

Then('the room inventory should contain that mobile') do
  found = @room_test_room.inventory.find(@room_test_added_mobile.game_object_id)
  assert_not_nil found, "Expected room inventory to contain the added mobile"
end

Then('the room exit {string} should return the exit') do |direction|
  result = @room_test_room.exit(direction)
  assert_not_nil result, "Expected room.exit('#{direction}') to return an exit"
end

Then('the room players list should contain only visible players') do
  result = @room_test_room.players
  assert result.is_a?(Array), "Expected players to return an Array"
  result.each do |p|
    assert p.is_a?(RoomTestPlayer), "Expected all items to be players"
    assert p.visible, "Expected all returned players to be visible"
  end
end

Then('the room players list with only_visible false should include invisible players') do
  result = @room_test_room.players(false)
  names = result.map(&:name)
  assert names.include?("Bob"), "Expected invisible player Bob in list, got: #{names.inspect}"
end

Then('the room mobiles list should contain only visible alive mobiles') do
  result = @room_test_room.mobiles
  assert result.is_a?(Array), "Expected mobiles to return an Array"
  assert result.length > 0, "Expected at least one mobile"
  result.each do |m|
    assert m.visible, "Expected all mobiles to be visible"
    assert m.alive, "Expected all mobiles to be alive"
  end
  # Ensure players are not included
  result.each do |m|
    refute m.is_a?(Aethyr::Core::Objects::Player), "Players should not be in mobiles list"
  end
end

Then('the room things list should contain only non-exit non-alive items') do
  result = @room_test_room.things
  assert result.is_a?(Array), "Expected things to return an Array"
  assert result.length > 0, "Expected at least one thing"
  result.each do |t|
    refute t.is_a?(Aethyr::Core::Objects::Exit), "Exits should not be in things list"
  end
end

Then('the room exits list should contain only exits') do
  result = @room_test_room.exits
  assert result.is_a?(Array), "Expected exits to return an Array"
  assert result.length > 0, "Expected at least one exit"
  result.each do |e|
    assert e.is_a?(RoomTestExit), "Expected all items to be exits"
  end
end

Then('the room look should say cannot see while blind') do
  result = @room_test_room.look(@room_test_look_player)
  assert_equal "You cannot see while you are blind", result
end

Then('the room look should contain {string}') do |fragment|
  result = @room_test_room.look(@room_test_look_player)
  assert result.include?(fragment),
    "Expected look output to contain '#{fragment}', got:\n#{result}"
end

Then('show_players should return text containing the player name') do
  result = @room_test_room.show_players(@room_test_look_player)
  assert_not_nil result, "Expected show_players to return a string, got nil"
  assert result.is_a?(String), "Expected show_players to return a String"
  assert result.length > 0, "Expected non-empty show_players output"
end

Then('show_players should return nil') do
  result = @room_test_room.show_players(@room_test_look_player)
  assert_nil result, "Expected show_players to return nil when no other players"
end
