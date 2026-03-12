# frozen_string_literal: true
###############################################################################
# Step definitions for AlookCommand action coverage.                          #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/actions/commands/alook'
require_relative '../support/test_helpers'

World(Test::Unit::Assertions)

# Re-load the source file so SimpleCov can instrument it (the Rakefile may
# have loaded it before SimpleCov started).
$alook_reloaded ||= false
Before do
  unless $alook_reloaded
    $alook_reloaded = true
    load File.expand_path('lib/aethyr/core/actions/commands/alook.rb')
  end
end

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module AlookWorld
  attr_accessor :alook_player, :alook_at, :alook_room, :alook_find_result,
                :alook_find_returns_nil
end
World(AlookWorld)

###############################################################################
# Lightweight doubles                                                         #
###############################################################################

# Recording player double that captures output messages.
class AlookPlayer
  attr_accessor :container, :name, :goid
  attr_reader :messages

  def initialize
    @container = "alook_room_goid_1"
    @name      = "TestAdmin"
    @goid      = "alook_player_goid_1"
    @messages  = []
  end

  def output(msg, *_args)
    @messages << msg.to_s
  end
end

# A simple inventory item double.
class AlookInventoryItem
  attr_reader :name, :goid

  def initialize(name, goid)
    @name = name
    @goid = goid
  end
end

# A simple inventory double that responds to each and position.
class AlookInventory
  def initialize(items, positions = {})
    @items = items
    @positions = positions
  end

  def each(&block)
    @items.each(&block)
  end

  def position(obj)
    @positions[obj.goid]
  end
end

# A simple equipment double.
class AlookEquipment
  attr_reader :inventory

  def initialize(items, equip_hash = {})
    @inventory = AlookInventory.new(items)
    @equip_hash = equip_hash
  end

  def equipment
    @equip_hash
  end
end

# A flexible room/object double for alook tests.
class AlookRoomDouble
  attr_reader :name, :goid

  def initialize(name: "TestRoom", goid: "alook_room_goid_1")
    @name = name
    @goid = goid
    @has_inventory = false
    @has_equipment = false
    @inventory = nil
    @equipment_obj = nil
  end

  def setup_inventory(items, positions = {})
    @has_inventory = true
    @inventory = AlookInventory.new(items, positions)
  end

  def remove_inventory_method!
    @has_inventory = false
    # Remove respond_to? for :inventory by using a flag
    @no_inventory_method = true
  end

  def setup_equipment(items, equip_hash = {})
    @has_equipment = true
    @equipment_obj = AlookEquipment.new(items, equip_hash)
  end

  def setup_observer_peers(peers_hash)
    @observer_peers = peers_hash
  end

  def setup_local_registrations(registrations)
    @local_registrations = registrations
  end

  def respond_to?(method, include_private = false)
    if method == :inventory || method == 'inventory'
      return false if @no_inventory_method
      return @has_inventory
    end
    if method == :equipment || method == 'equipment'
      return @has_equipment
    end
    super
  end

  def inventory
    @inventory
  end

  def equipment
    @equipment_obj
  end

  def to_s
    "AlookRoomDouble<#{@name}>"
  end
end

# A simple listener double for @local_registrations
class AlookListenerDouble
  def initialize(name)
    @listener = name
  end
end

# A registration entry double for @local_registrations
class AlookRegistrationEntry
  def initialize(listener_name)
    @listener = listener_name
  end
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed AlookCommand environment') do
  @alook_player          = AlookPlayer.new
  @alook_at              = nil
  @alook_find_result     = nil
  @alook_find_returns_nil = false

  # Default room double with a basic inventory
  @alook_room = AlookRoomDouble.new

  # Ensure `log` is available as a no-op
  unless Object.private_method_defined?(:log)
    Object.class_eval do
      private
      def log(_msg, *_args); end
    end
  end

  # Track if log was called
  @alook_log_called = false

  # Build a stub manager
  room_ref   = @alook_room
  player_ref = @alook_player
  alook_world = self

  mgr = Object.new

  mgr.define_singleton_method(:get_object) do |goid|
    if goid == player_ref.container
      alook_world.alook_room
    else
      nil
    end
  end

  mgr.define_singleton_method(:find) do |name_or_goid, *args|
    if name_or_goid == player_ref.container
      alook_world.alook_room
    elsif alook_world.alook_find_returns_nil
      nil
    elsif alook_world.alook_find_result
      alook_world.alook_find_result
    else
      nil
    end
  end

  $manager = mgr

  # Stub ServerConfig if not yet defined
  unless defined?(::ServerConfig)
    module ::ServerConfig
      @data = {}
      class << self
        def [](key);       @data[key]; end
        def []=(key, val); @data[key] = val; end
      end
    end
  end

  # Set up $LOG so the `log` method doesn't crash
  unless $LOG
    log_double = Object.new
    log_double.define_singleton_method(:add) do |*args, **kwargs|
      # no-op
    end
    log_double.define_singleton_method(:dump) { }
    $LOG = log_double
  end
end

Given('the alook at target is not set') do
  @alook_at = nil
end

Given('the alook at target is {string}') do |target|
  @alook_at = target
end

Given('the alook manager can find object {string}') do |name|
  item = AlookRoomDouble.new(name: name, goid: "alook_found_#{name}")
  @alook_find_result = item
  @alook_find_returns_nil = false
end

Given('the alook manager cannot find object {string}') do |_name|
  @alook_find_result = nil
  @alook_find_returns_nil = true
end

Given('the alook room has inventory') do
  item = AlookInventoryItem.new("TestItem", "alook_item_1")
  @alook_room.setup_inventory([item], { "alook_item_1" => nil })
end

Given('the alook room has no inventory method') do
  @alook_room.remove_inventory_method!
end

Given('the alook room has equipment') do
  armor = AlookInventoryItem.new("TestArmor", "alook_armor_1")
  @alook_room.setup_equipment([armor], { torso: "alook_armor_1" })
end

Given('the alook room has observer_peers') do
  # observer_peers is a hash keyed by objects - keys get .to_s called on them
  peer_key = Object.new
  peer_key.define_singleton_method(:to_s) { "ObserverPeerObj" }
  @alook_room.setup_observer_peers({ peer_key => [:some_method] })
end

Given('the alook room has local_registrations') do
  reg = AlookRegistrationEntry.new("SomeListenerName")
  @alook_room.setup_local_registrations([reg])
end

Given('the alook room has inventory with nil position') do
  item = AlookInventoryItem.new("TestItem", "alook_item_nil_pos")
  @alook_room.setup_inventory([item], { "alook_item_nil_pos" => nil })
end

Given('the alook room has inventory with position') do
  item = AlookInventoryItem.new("TestItem", "alook_item_pos")
  @alook_room.setup_inventory([item], { "alook_item_pos" => [3, 4] })
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('the AlookCommand action is invoked') do
  data = {}
  data[:at] = @alook_at unless @alook_at.nil?
  # Need to pass :actor for find_object to work (it accesses event[:actor])
  data[:actor] = @alook_player

  cmd = Aethyr::Core::Actions::Alook::AlookCommand.new(@alook_player, **data)

  # Track log calls
  alook_world = self
  cmd.define_singleton_method(:log) do |msg, *args|
    alook_world.instance_variable_set(:@alook_log_called, true)
  end

  cmd.action
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the alook player should see {string}') do |fragment|
  match = @alook_player.messages.any? { |m| m.include?(fragment) }
  assert(match,
    "Expected alook player output containing #{fragment.inspect}, got: #{@alook_player.messages.inspect}")
end

Then('the alook output should have been logged') do
  assert(@alook_log_called,
    "Expected log to have been called, but it was not.")
end

Then('the alook inventory line should not contain position dimensions') do
  # Find the inventory line with TestItem and check it doesn't have dimensions like "3x4"
  output = @alook_player.messages.last
  # Extract just the inventory line for TestItem
  item_line = output.lines.find { |l| l.include?("TestItem") }
  assert(item_line, "Expected to find a line with TestItem in output")
  # The line should end with just the goid and no dimensions
  refute_match(/\d+x\d+/, item_line,
    "Expected no position dimensions in inventory line, got: #{item_line.inspect}")
end
