# frozen_string_literal: true

###############################################################################
# Step-definitions for Equipment object scenarios                              #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'

World(Test::Unit::Assertions)

###############################################################################
# Helpers and stubs                                                            #
###############################################################################
module EquipmentWorld
  attr_accessor :equip, :items, :wear_result, :remove_result, :mock_wearer

  # Minimal $manager stub for Equipment tests.
  # Equipment#wear calls $manager.get_object(item.container).
  class EquipStubManager
    def initialize
      @objects = {}
    end

    def existing_goid?(_goid)
      false
    end

    def submit_action(_action); end

    def register(obj)
      @objects[obj.goid] = obj
    end

    def get_object(goid)
      @objects[goid]
    end
  end

  # A lightweight mock that looks like a wearable game object.
  # It quacks like a Wearable + GameObject for Equipment's purposes.
  class MockWearableItem
    attr_accessor :container, :info
    attr_reader :game_object_id, :alt_names

    def initialize(name, position, layer, goid = nil)
      @name = name
      @game_object_id = goid || "goid_#{name.gsub(/\s/, '_')}"
      @alt_names = [name]
      @info = MockInfo.new
      @info.position = position.to_sym
      @info.layer = layer
      @container = nil
    end

    def goid
      @game_object_id
    end

    def name
      @name
    end

    def generic
      @name
    end

    def position
      @info.position
    end

    def layer
      @info.layer
    end

    def is_a?(klass)
      return true if defined?(::Wearable) && klass == ::Wearable
      return true if defined?(::GameObject) && klass == ::GameObject
      super
    end

    def can_move?
      true
    end
  end

  # A mock for non-wearable items.
  class MockNonWearableItem
    attr_accessor :container, :info
    attr_reader :game_object_id, :alt_names

    def initialize(name, goid = nil)
      @name = name
      @game_object_id = goid || "goid_#{name.gsub(/\s/, '_')}"
      @alt_names = [name]
      @info = MockInfo.new
      @container = nil
    end

    def goid
      @game_object_id
    end

    def name
      @name
    end

    def generic
      @name
    end

    def position
      @info.position
    end

    def layer
      @info.layer || 0
    end

    def is_a?(klass)
      return false if defined?(::Wearable) && klass == ::Wearable
      super
    end
  end

  # Minimal Info stub using OpenStruct behavior.
  class MockInfo < OpenStruct; end

  # A mock container (non-Player) to test Equipment#wear removing from container.
  class MockContainer
    attr_reader :removed_items

    def initialize
      @removed_items = []
    end

    def remove(item)
      @removed_items << item
    end

    def is_a?(klass)
      # Specifically NOT a Player
      return false if klass == Player
      super
    end
  end

  # A mock wearer (another character) for show methods.
  class MockWearer
    attr_reader :name

    def initialize(name = "Bob", sex = 'm')
      @name = name
      @sex = sex
    end

    def pronoun(type = :normal)
      case type
      when :normal
        @sex == 'm' ? "he" : "she"
      when :possessive
        @sex == 'm' ? "his" : "her"
      when :objective
        @sex == 'm' ? "him" : "her"
      else
        "they"
      end
    end

    def ==(other)
      other == "You" ? false : super
    end
  end

  # Player class stand-in so we can check `is_a? Player`
  # We define ::Player at top-level if it isn't already defined.
end

World(EquipmentWorld)

###############################################################################
# Steps                                                                        #
###############################################################################

Given('I require the Equipment library') do
  $manager ||= EquipmentWorld::EquipStubManager.new
  # Make sure we have the Player constant for Equipment#wear checks.
  unless defined?(::Player)
    Object.const_set(:Player, Class.new)
  end
  # Equipment#delete checks `goid.is_a? GameObject`
  # Gary#delete checks `object.is_a?(Aethyr::Core::Objects::GameObject)`
  unless defined?(Aethyr::Core::Objects::GameObject)
    module ::Aethyr; module Core; module Objects
      class GameObject; end
    end; end; end
  end
  unless defined?(::GameObject)
    Object.const_set(:GameObject, Aethyr::Core::Objects::GameObject)
  end
  # Equipment#check_position checks `item.is_a? Wearable`
  unless defined?(::Wearable)
    Object.const_set(:Wearable, Module.new)
  end
  require 'aethyr/core/objects/equipment'
  self.items = {}
end

When('I create a new Equipment object with player goid {string}') do |goid|
  $manager = EquipmentWorld::EquipStubManager.new
  self.equip = Equipment.new(goid)
end

# ── Item creation ─────────────────────────────────────────────────

Given('I create a wearable item named {string} at position {string} layer {int}') do |name, pos, layer|
  item = EquipmentWorld::MockWearableItem.new(name, pos, layer)
  $manager.register(item)
  self.items ||= {}
  self.items[name] = item
end

Given('I create a wearable item named {string} at position {string} layer {int} with container') do |name, pos, layer|
  item = EquipmentWorld::MockWearableItem.new(name, pos, layer)
  container = EquipmentWorld::MockContainer.new
  $manager.register(container) if container.respond_to?(:goid)
  # Simulate item being in a non-Player container
  mock_container_goid = "container_#{name}"
  item.container = mock_container_goid
  # Register a mock container object that $manager.get_object can find
  mock_obj = EquipmentWorld::MockContainer.new
  # We need $manager.get_object to return this container
  # Patch it in through our stub
  $manager.instance_variable_get(:@objects)[mock_container_goid] = mock_obj
  $manager.register(item)
  self.items ||= {}
  self.items[name] = item
end

Given('I create a weapon item named {string} at position {string} layer {int}') do |name, pos, layer|
  item = EquipmentWorld::MockWearableItem.new(name, pos, layer)
  $manager.register(item)
  self.items ||= {}
  self.items[name] = item
end

Given('I create a non-wearable item named {string}') do |name|
  item = EquipmentWorld::MockNonWearableItem.new(name)
  $manager.register(item)
  self.items ||= {}
  self.items[name] = item
end

# ── Wear / Remove / Delete ────────────────────────────────────────

Given('I wear the item {string} on the equipment') do |name|
  item = items[name]
  self.wear_result = equip.wear(item)
end

When('I wear item {string} with position {string} on equipment') do |name, pos|
  item = items[name]
  self.wear_result = equip.wear(item, pos)
end

When('I try to wear item {string} on the equipment') do |name|
  item = items[name]
  self.wear_result = equip.wear(item)
end

Given('I remove item {string} from the equipment') do |name|
  item = items[name]
  self.remove_result = equip.remove(item)
end

Given('I delete item {string} from the equipment by goid') do |name|
  item = items[name]
  equip.delete(item.goid)
end

Given('I delete game object {string} from the equipment') do |name|
  item = items[name]
  equip.delete(item)
end

# ── Equipment slot manipulation ───────────────────────────────────

Given('I set equipment slot {string} to an array of nils') do |slot|
  equip.equipment[slot.to_sym] = [nil, nil, nil]
end

Given('I set equipment slot {string} to an empty array') do |slot|
  equip.equipment[slot.to_sym] = []
end

Given('I set equipment slot {string} to array with nil first and nil rest') do |slot|
  equip.equipment[slot.to_sym] = [nil, nil, nil]
end

# ── Assertions: basic ─────────────────────────────────────────────

Then('the equipment hash should be empty') do
  assert equip.equipment.empty?, "Expected equipment hash to be empty"
end

Then('the equipment goid should be {string}') do |expected|
  assert_equal expected, equip.goid
end

Then('the equipment string representation should include {string}') do |expected|
  result = equip.send(:to_s)
  assert result.include?(expected), "Expected '#{result}' to include '#{expected}'"
end

# ── Assertions: worn_or_wielded? ──────────────────────────────────

Given('I check worn_or_wielded for an item not in inventory') do
  fake_item = EquipmentWorld::MockWearableItem.new("nonexistent", "head", 0, "fake_goid")
  @wow_result = equip.worn_or_wielded?(fake_item.name)
end

Given('I check worn_or_wielded for item {string}') do |name|
  @wow_result = equip.worn_or_wielded?(name)
end

Then('worn_or_wielded should return false') do
  assert_equal false, @wow_result
end

Then('worn_or_wielded should return a remove message for {string}') do |name|
  assert @wow_result.is_a?(String), "Expected a string message, got #{@wow_result.inspect}"
  assert @wow_result.include?("remove"), "Expected remove message, got: #{@wow_result}"
  assert @wow_result.include?(name), "Expected message to include '#{name}', got: #{@wow_result}"
end

Then('worn_or_wielded should return an unwield message for {string}') do |name|
  assert @wow_result.is_a?(String), "Expected a string message, got #{@wow_result.inspect}"
  assert @wow_result.include?("unwield"), "Expected unwield message, got: #{@wow_result}"
  assert @wow_result.include?(name), "Expected message to include '#{name}', got: #{@wow_result}"
end

# ── Assertions: get_wielded ───────────────────────────────────────

Then('get_wielded with no argument should return nil') do
  assert_nil equip.get_wielded
end

Then('get_wielded with {string} should return item {string}') do |hand, name|
  result = equip.get_wielded(hand)
  assert_not_nil result, "Expected get_wielded('#{hand}') to return an item, got nil"
  assert_equal name, result.name
end

Then('get_wielded with no argument should return item {string}') do |name|
  result = equip.get_wielded
  assert_not_nil result, "Expected get_wielded to return an item, got nil"
  assert_equal name, result.name
end

Then('get_wielded with {string} should return nil') do |hand|
  assert_nil equip.get_wielded(hand)
end

# ── Assertions: get_all_wielded ───────────────────────────────────

Then('get_all_wielded should return {int} items') do |count|
  result = equip.get_all_wielded
  assert_equal count, result.length
end

# ── Assertions: check_wield ──────────────────────────────────────

Then('check_wield for item {string} should return nil') do |name|
  item = items[name]
  result = equip.check_wield(item)
  assert_nil result, "Expected check_wield to return nil, got: #{result}"
end

Then('check_wield for item {string} with position {string} should return nil') do |name, pos|
  item = items[name]
  result = equip.check_wield(item, pos)
  assert_nil result, "Expected check_wield to return nil, got: #{result}"
end

Then('check_wield for item {string} should return {string}') do |name, expected|
  item = items[name]
  result = equip.check_wield(item)
  assert_equal expected, result
end

# ── Assertions: wear ─────────────────────────────────────────────

Then('the item {string} should be in the equipment at position {string}') do |name, pos|
  item = items[name]
  slot = equip.equipment[pos.to_sym]
  assert_not_nil slot, "Expected equipment slot :#{pos} to exist"
  assert_equal item.goid, slot[item.layer], "Expected item goid in slot"
end

Then('wear should return nil') do
  assert_nil wear_result, "Expected wear to return nil"
end

Then('the item {string} should have nil container') do |name|
  item = items[name]
  assert_nil item.container, "Expected container to be nil"
end

Then('the item {string} should have equipment_of set to {string}') do |name, player_goid|
  item = items[name]
  assert_equal player_goid, item.info.equipment_of
end

Then('the item {string} should have container set to {string}') do |name, expected|
  item = items[name]
  assert_equal expected, item.container
end

Then('the item {string} should be in the equipment at some position') do |name|
  item = items[name]
  found = false
  equip.equipment.each do |_pos, slot|
    if slot && slot.include?(item.goid)
      found = true
      break
    end
  end
  assert found, "Expected item '#{name}' to be in equipment at some position"
end

# ── Assertions: remove ────────────────────────────────────────────

Then('remove should return true') do
  assert_equal true, remove_result
end

Then('remove should return false') do
  assert_equal false, remove_result
end

# ── Assertions: delete ────────────────────────────────────────────

Then('the equipment should not contain item {string}') do |name|
  item = items[name]
  found = false
  equip.equipment.each do |_pos, slot|
    if slot && slot.include?(item.goid)
      found = true
      break
    end
  end
  assert !found, "Expected item '#{name}' to not be in equipment"
end

# ── Assertions: find ──────────────────────────────────────────────

Then('find should locate item {string}') do |name|
  result = equip.find(name)
  assert_not_nil result, "Expected find to locate item '#{name}'"
  assert_equal name, result.name
end

# ── Assertions: position_of ──────────────────────────────────────

Then('position_of should return {string} for item {string}') do |pos, name|
  item = items[name]
  result = equip.position_of(item)
  assert_equal pos.to_sym, result
end

Then('position_of should return nil for item {string}') do |name|
  item = items[name]
  result = equip.position_of(item)
  assert_nil result
end

Then('position_of with generic position {string} should find item {string}') do |pos, name|
  item = items[name]
  result = equip.position_of(item, pos)
  assert_not_nil result, "Expected position_of to find item with generic position '#{pos}'"
end

Then('position_of with string position {string} should return {string} for item {string}') do |pos, expected, name|
  item = items[name]
  result = equip.position_of(item, pos)
  assert_equal expected.to_sym, result
end

# ── Assertions: each ──────────────────────────────────────────────

Then('each should yield {int} item') do |count|
  collected = []
  equip.each { |i| collected << i }
  assert_equal count, collected.length
end

# ── Assertions: [] accessor ──────────────────────────────────────

Then('bracket accessor for {string} should return the goid of item {string}') do |pos, name|
  item = items[name]
  slot = equip[pos.to_sym]
  assert_not_nil slot
  assert_equal item.goid, slot[item.layer]
end

# ── Assertions: show ─────────────────────────────────────────────

Then('show for {string} should include {string}') do |wearer, expected|
  result = equip.show(wearer)
  assert result.include?(expected), "Expected show output to include '#{expected}', got:\n#{result}"
end

Then('show for another wearer should include {string}') do |expected|
  self.mock_wearer ||= EquipmentWorld::MockWearer.new("Bob", "m")
  result = equip.show(mock_wearer)
  assert result.include?(expected), "Expected show output to include '#{expected}', got:\n#{result}"
end

# ── Assertions: show_position ────────────────────────────────────

Then('show_position for {string} for {string} should return nil') do |pos, wearer|
  result = equip.show_position(pos.to_sym, wearer)
  assert_nil result, "Expected show_position to return nil, got: #{result}"
end

Then('show_position for {string} for {string} should include {string}') do |pos, wearer, expected|
  result = equip.show_position(pos.to_sym, wearer)
  assert_not_nil result, "Expected show_position to return a string"
  assert result.include?(expected), "Expected show_position to include '#{expected}', got: #{result}"
end

Then('show_position for {string} for another wearer should include {string}') do |pos, expected|
  self.mock_wearer ||= EquipmentWorld::MockWearer.new("Bob", "m")
  result = equip.show_position(pos.to_sym, mock_wearer)
  assert_not_nil result, "Expected show_position to return a string for another wearer"
  assert result.include?(expected), "Expected show_position to include '#{expected}', got: #{result}"
end

Then('show_position for {string} for another wearer should return nil') do |pos|
  self.mock_wearer ||= EquipmentWorld::MockWearer.new("Bob", "m")
  result = equip.show_position(pos.to_sym, mock_wearer)
  assert_nil result, "Expected show_position to return nil for another wearer, got: #{result}"
end

# ── Assertions: show_wielding ────────────────────────────────────

Then('show_wielding for {string} should include {string}') do |wearer, expected|
  result = equip.show_wielding(wearer)
  output = result.is_a?(Array) ? result.join("\n") : result.to_s
  assert output.include?(expected), "Expected show_wielding to include '#{expected}', got:\n#{output}"
end

Then('show_wielding for another wearer should include {string}') do |expected|
  self.mock_wearer ||= EquipmentWorld::MockWearer.new("Bob", "m")
  result = equip.show_wielding(mock_wearer)
  output = result.is_a?(Array) ? result.join("\n") : result.to_s
  assert output.include?(expected), "Expected show_wielding to include '#{expected}', got:\n#{output}"
end

# ── Assertions: check_position ───────────────────────────────────

Then('check_position for item {string} should return {string}') do |name, expected|
  item = items[name]
  result = equip.check_position(item)
  assert_equal expected, result
end

Then('check_position for item {string} should return nil') do |name|
  item = items[name]
  result = equip.check_position(item)
  assert_nil result, "Expected check_position to return nil, got: #{result}"
end

Then('check_position for item {string} with position {string} should return nil') do |name, pos|
  item = items[name]
  result = equip.check_position(item, pos)
  assert_nil result, "Expected check_position to return nil, got: #{result}"
end

Then('check_position for item {string} with position {string} should include {string}') do |name, pos, expected|
  item = items[name]
  result = equip.check_position(item, pos)
  assert_not_nil result, "Expected check_position to return a message"
  assert result.include?(expected), "Expected '#{result}' to include '#{expected}'"
end

Then('check_position for item {string} should include {string}') do |name, expected|
  item = items[name]
  result = equip.check_position(item)
  assert_not_nil result, "Expected check_position to return a message"
  assert result.include?(expected), "Expected '#{result}' to include '#{expected}'"
end

Then('check_position for item {string} with nil position should return nil') do |name|
  item = items[name]
  result = equip.check_position(item, nil)
  assert_nil result, "Expected check_position to return nil, got: #{result}"
end
