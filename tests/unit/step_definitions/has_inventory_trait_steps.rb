# frozen_string_literal: true

###############################################################################
# Step definitions for the HasInventory trait feature.                         #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/objects/inventory'
require 'aethyr/core/objects/traits/has_inventory'

World(Test::Unit::Assertions)

###############################################################################
# Minimal test doubles that satisfy the interfaces HasInventory depends on.    #
###############################################################################
module HasInventoryWorld
  # A minimal item double with enough interface for Gary/Inventory lookups.
  class InvTestItem
    attr_accessor :game_object_id, :name, :alt_names, :generic,
                  :container, :visible, :quantity, :article, :short_desc

    def initialize(opts = {})
      @game_object_id = opts[:goid] || "inv_item_#{rand(99999)}"
      @name           = opts[:name] || "thing"
      @alt_names      = opts[:alt_names] || []
      @generic        = opts[:generic] || @name
      @visible        = true
      @quantity       = 1
      @article        = "a"
      @short_desc     = ""
      @container      = nil
    end

    def plural
      "#{@name}s"
    end
  end

  # A minimal fake equipment object with a find method backed by an Inventory.
  class FakeEquipment
    def initialize
      @inventory = Inventory.new
    end

    def add(item)
      @inventory << item
    end

    def find(item_name)
      @inventory.find(item_name)
    end
  end

  # Base class without equipment — search_inv should only search @inventory.
  # Defines can? as alias for respond_to? (mirrors GameObject behaviour).
  class HasInvTestBase
    include HasInventory
    alias :can? :respond_to?

    def initialize
      super
    end
  end

  # Subclass that also responds to :equipment — search_inv should fall back
  # to @equipment when @inventory.find returns nil.
  class HasInvTestWithEquipment
    include HasInventory
    alias :can? :respond_to?

    attr_reader :equipment

    def initialize
      super
      @equipment = FakeEquipment.new
    end
  end

  attr_accessor :has_inv_object, :has_inv_search_result, :has_inv_item
end
World(HasInventoryWorld)

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('a has_inventory test object') do
  self.has_inv_object = HasInventoryWorld::HasInvTestBase.new
end

Given('a has_inventory test object with equipment') do
  self.has_inv_object = HasInventoryWorld::HasInvTestWithEquipment.new
end

Given('an item named {string} is in the has_inventory object inventory') do |name|
  self.has_inv_item = HasInventoryWorld::InvTestItem.new(goid: "inv_#{name}", name: name)
  has_inv_object.inventory << has_inv_item
end

Given('an item named {string} is in the has_inventory object equipment') do |name|
  self.has_inv_item = HasInventoryWorld::InvTestItem.new(goid: "eq_#{name}", name: name)
  has_inv_object.equipment.add(has_inv_item)
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('I search_inv for {string} on the has_inventory object') do |item_name|
  self.has_inv_search_result = has_inv_object.search_inv(item_name)
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the has_inventory search result should be the item named {string}') do |name|
  assert_not_nil(has_inv_search_result,
                 "Expected search_inv to return an item, got nil")
  assert_equal(name, has_inv_search_result.name,
               "Expected item named '#{name}', got '#{has_inv_search_result.name}'")
end

Then('the has_inventory search result should be nil') do
  assert_nil(has_inv_search_result,
             "Expected search_inv to return nil, got #{has_inv_search_result.inspect}")
end
