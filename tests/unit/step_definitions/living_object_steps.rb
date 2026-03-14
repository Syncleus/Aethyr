# frozen_string_literal: true

###############################################################################
# Step definitions for LivingObject scenarios (living.rb)                      #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module to hold scenario state
# ---------------------------------------------------------------------------
module LivingObjectWorld
  attr_accessor :living_instance, :living_items, :living_wear_result,
                :living_remove_result, :living_death_message_result,
                :living_output_messages, :living_log_messages

  # Stub equipment that lets us control check_position, wear, and remove
  # return values without involving the real Equipment class.
  class StubEquipment
    attr_accessor :check_position_result, :wear_result, :remove_result

    def initialize
      @check_position_result = nil
      @wear_result = nil
      @remove_result = false
    end

    def check_position(item, position = nil)
      @check_position_result
    end

    def wear(item, position = nil)
      @wear_result
    end

    def remove(item)
      @remove_result
    end

    # Needed by Mobile#long_desc and other display methods
    def show(wearer = "You")
      "Not wielding anything.\nWearing nothing."
    end
  end

  # Stub inventory that tracks add/remove calls
  class StubInventory
    attr_reader :items

    def initialize
      @items = []
    end

    def add(item)
      @items << item
    end

    def remove(item)
      @items.delete(item)
    end

    def include?(item)
      @items.include?(item)
    end

    def show
      "nothing"
    end
  end

  # Lightweight item mock for LivingObject tests
  class LivingMockItem
    attr_accessor :container, :info
    attr_reader :game_object_id, :name

    def initialize(name, position, layer)
      @name = name
      @game_object_id = "living_goid_#{name}"
      @info = OpenStruct.new(position: position.to_sym, layer: layer)
      @container = nil
    end

    def goid
      @game_object_id
    end

    def position
      @info.position
    end

    def layer
      @info.layer
    end
  end

  # Stub manager for LivingObject tests
  class LivingStubManager
    def existing_goid?(_goid)
      false
    end

    def submit_action(_action); end

    def get_object(_goid)
      nil
    end
  end
end
World(LivingObjectWorld)

# ---------------------------------------------------------------------------
# Background / setup
# ---------------------------------------------------------------------------
Given('the LivingObject test dependencies are loaded') do
  unless defined?(ServerConfig)
    module ::ServerConfig
      @data = {}
      class << self
        def [](key);       @data[key]; end
        def []=(key, val); @data[key] = val; end
        def reset!;        @data.clear; end
      end
    end
  end
  ServerConfig[:log_level] ||= 0

  unless defined?($LOG) && $LOG
    require 'aethyr/core/util/log'
    $LOG = Logger.new('logs/test_living.log')
  end

  $manager = LivingObjectWorld::LivingStubManager.new

  Object.const_set(:Generic, :Generic) unless defined?(Generic)

  require 'aethyr/core/objects/mobile'
end

# ---------------------------------------------------------------------------
# Object creation
# ---------------------------------------------------------------------------
Given('a LivingObject is created') do
  $manager = LivingObjectWorld::LivingStubManager.new
  self.living_instance = Aethyr::Core::Objects::Mobile.new
  self.living_items = {}
  self.living_output_messages = []
  self.living_log_messages = []

  # Replace equipment with our stub
  stub_equip = LivingObjectWorld::StubEquipment.new
  living_instance.instance_variable_set(:@equipment, stub_equip)

  # Replace inventory with our stub
  stub_inv = LivingObjectWorld::StubInventory.new
  living_instance.instance_variable_set(:@inventory, stub_inv)

  # Capture output calls (LivingObject#wear calls self.output)
  captured = living_output_messages
  log_captured = living_log_messages
  living_instance.define_singleton_method(:output) do |*args|
    captured << args[0]
  end

  # Capture log calls for unknown damage type testing
  living_instance.define_singleton_method(:log) do |*args|
    log_captured << args[0]
  end

  # Stub alert to avoid Wisper broadcast issues in test
  living_instance.define_singleton_method(:alert) do |*args|
    # no-op for tests
  end
end

# ---------------------------------------------------------------------------
# Item creation
# ---------------------------------------------------------------------------
Given('a wearable item {string} at position {string} layer {int} exists') do |name, pos, layer|
  item = LivingObjectWorld::LivingMockItem.new(name, pos, layer)
  self.living_items[name] = item
end

# ---------------------------------------------------------------------------
# Equipment stubbing
# ---------------------------------------------------------------------------
Given('the equipment check_position will return {string}') do |message|
  living_instance.instance_variable_get(:@equipment).check_position_result = message
end

Given('the equipment check_position will return nil') do
  living_instance.instance_variable_get(:@equipment).check_position_result = nil
end

Given('the equipment wear will succeed for item {string}') do |name|
  # Equipment#wear returns item.info.equipment_of (truthy) on success
  living_instance.instance_variable_get(:@equipment).wear_result = true
end

Given('the equipment wear will fail') do
  living_instance.instance_variable_get(:@equipment).wear_result = nil
end

Given('the equipment remove will succeed for item {string}') do |name|
  living_instance.instance_variable_get(:@equipment).remove_result = true
end

Given('the equipment remove will fail') do
  living_instance.instance_variable_get(:@equipment).remove_result = false
end

# ---------------------------------------------------------------------------
# Inventory setup
# ---------------------------------------------------------------------------
Given('the LivingObject inventory contains item {string}') do |name|
  item = living_items[name]
  living_instance.instance_variable_get(:@inventory).add(item)
end

# ---------------------------------------------------------------------------
# Stat setup
# ---------------------------------------------------------------------------
Given('the LivingObject has stamina set to {int}') do |value|
  living_instance.info.stats.stamina = value
end

Given('the LivingObject has fortitude set to {int}') do |value|
  living_instance.info.stats.fortitude = value
end

Given('the LivingObject has a custom death_message {string}') do |message|
  living_instance.info.death_message = message
end

# ---------------------------------------------------------------------------
# Actions: wear
# ---------------------------------------------------------------------------
When('I call wear on the LivingObject with item {string}') do |name|
  item = living_items[name]
  self.living_wear_result = living_instance.wear(item)
end

# ---------------------------------------------------------------------------
# Actions: remove
# ---------------------------------------------------------------------------
When('I call remove on the LivingObject with item {string}') do |name|
  item = living_items[name]
  self.living_remove_result = living_instance.remove(item)
end

# ---------------------------------------------------------------------------
# Actions: take_damage
# ---------------------------------------------------------------------------
When('I call take_damage on the LivingObject with amount {int} and type health') do |amount|
  living_instance.take_damage(amount, :health)
end

When('I call take_damage on the LivingObject with amount {int} and type stamina') do |amount|
  living_instance.take_damage(amount, :stamina)
end

When('I call take_damage on the LivingObject with amount {int} and type fortitude') do |amount|
  living_instance.take_damage(amount, :fortitude)
end

When('I call take_damage on the LivingObject with amount {int} and type magic') do |amount|
  living_instance.take_damage(amount, :magic)
end

# ---------------------------------------------------------------------------
# Actions: death_message
# ---------------------------------------------------------------------------
When('I call death_message on the LivingObject') do
  self.living_death_message_result = living_instance.death_message
end

# ---------------------------------------------------------------------------
# Assertions: wear
# ---------------------------------------------------------------------------
Then('the LivingObject wear result should be false') do
  assert_equal false, living_wear_result
end

Then('the LivingObject wear result should be true') do
  assert_equal true, living_wear_result
end

Then('the LivingObject output should include {string}') do |expected|
  found = living_output_messages.any? { |m| m.to_s.include?(expected) }
  assert found, "Expected output to include '#{expected}', got: #{living_output_messages.inspect}"
end

# ---------------------------------------------------------------------------
# Assertions: remove
# ---------------------------------------------------------------------------
Then('the LivingObject remove result should be true') do
  assert_equal true, living_remove_result
end

Then('the LivingObject remove result should be false') do
  assert_equal false, living_remove_result
end

# ---------------------------------------------------------------------------
# Assertions: inventory
# ---------------------------------------------------------------------------
Then('the LivingObject inventory should not contain item {string}') do |name|
  item = living_items[name]
  inv = living_instance.instance_variable_get(:@inventory)
  assert !inv.include?(item), "Expected inventory to not contain '#{name}'"
end

Then('the LivingObject inventory should contain item {string}') do |name|
  item = living_items[name]
  inv = living_instance.instance_variable_get(:@inventory)
  assert inv.include?(item), "Expected inventory to contain '#{name}'"
end

# ---------------------------------------------------------------------------
# Assertions: stats
# ---------------------------------------------------------------------------
Then('the LivingObject health should be {int}') do |expected|
  assert_equal expected, living_instance.info.stats.health
end

Then('the LivingObject stamina should be {int}') do |expected|
  assert_equal expected, living_instance.info.stats.stamina
end

Then('the LivingObject fortitude should be {int}') do |expected|
  assert_equal expected, living_instance.info.stats.fortitude
end

# ---------------------------------------------------------------------------
# Assertions: logging
# ---------------------------------------------------------------------------
Then('the LivingObject should have logged unknown damage type {string}') do |type|
  found = living_log_messages.any? { |m| m.to_s.include?("Do not know this kind of damage") && m.to_s.include?(type) }
  assert found, "Expected log to include unknown damage message for '#{type}', got: #{living_log_messages.inspect}"
end

# ---------------------------------------------------------------------------
# Assertions: death_message
# ---------------------------------------------------------------------------
Then('the LivingObject death_message result should be {string}') do |expected|
  assert_equal expected, living_death_message_result
end

Then('the LivingObject death_message result should include {string}') do |expected|
  assert living_death_message_result.include?(expected),
         "Expected death_message to include '#{expected}', got: #{living_death_message_result.inspect}"
end
