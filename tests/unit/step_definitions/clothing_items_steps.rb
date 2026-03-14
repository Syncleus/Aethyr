# frozen_string_literal: true

###############################################################################
# Step-definitions for ClothingItems object scenarios                          #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

###############################################################################
# Minimal $manager stub – GameObject#initialize calls                          #
# $manager.existing_goid? to guarantee GOID uniqueness.                        #
###############################################################################
module ClothingItemsWorld
  attr_accessor :clothing_instance

  class ClothingStubManager
    def existing_goid?(_goid)
      false
    end

    def submit_action(action)
      # no-op
    end
  end
end
World(ClothingItemsWorld)

###############################################################################
# Steps                                                                        #
###############################################################################

Given('I require the ClothingItems library') do
  $manager ||= ClothingItemsWorld::ClothingStubManager.new
  require 'aethyr/extensions/objects/clothing_items'
end

# ── When: create instances ──────────────────────────────────────────

When('I create a new Shoes object') do
  $manager = ClothingItemsWorld::ClothingStubManager.new
  self.clothing_instance = Aethyr::Extensions::Objects::Shoes.new
end

When('I create a new Glove object') do
  $manager = ClothingItemsWorld::ClothingStubManager.new
  self.clothing_instance = Aethyr::Extensions::Objects::Glove.new
end

When('I create a new Necklace object') do
  $manager = ClothingItemsWorld::ClothingStubManager.new
  self.clothing_instance = Aethyr::Extensions::Objects::Necklace.new
end

When('I create a new Belt object') do
  $manager = ClothingItemsWorld::ClothingStubManager.new
  self.clothing_instance = Aethyr::Extensions::Objects::Belt.new
end

When('I create a new Breastplate object') do
  $manager = ClothingItemsWorld::ClothingStubManager.new
  self.clothing_instance = Aethyr::Extensions::Objects::Breastplate.new
end

# ── Then: generic ───────────────────────────────────────────────────

Then('the Shoes generic should be {string}') do |expected|
  assert_equal expected, clothing_instance.generic
end

Then('the Glove generic should be {string}') do |expected|
  assert_equal expected, clothing_instance.generic
end

Then('the Necklace generic should be {string}') do |expected|
  assert_equal expected, clothing_instance.generic
end

Then('the Belt generic should be {string}') do |expected|
  assert_equal expected, clothing_instance.generic
end

Then('the Breastplate generic should be {string}') do |expected|
  assert_equal expected, clothing_instance.generic
end

# ── Then: article ───────────────────────────────────────────────────

Then('the Shoes article should be {string}') do |expected|
  assert_equal expected, clothing_instance.article
end

# ── Then: position ──────────────────────────────────────────────────

Then('the Shoes position should be :feet') do
  assert_equal :feet, clothing_instance.info.position
end

Then('the Glove position should be :hand') do
  assert_equal :hand, clothing_instance.info.position
end

Then('the Necklace position should be :neck') do
  assert_equal :neck, clothing_instance.info.position
end

Then('the Belt position should be :waist') do
  assert_equal :waist, clothing_instance.info.position
end

Then('the Breastplate position should be :torso') do
  assert_equal :torso, clothing_instance.info.position
end

# ── Then: layer ─────────────────────────────────────────────────────

Then('the Shoes layer should be {int}') do |expected|
  assert_equal expected, clothing_instance.info.layer
end

Then('the Glove layer should be {int}') do |expected|
  assert_equal expected, clothing_instance.info.layer
end

Then('the Necklace layer should be {int}') do |expected|
  assert_equal expected, clothing_instance.info.layer
end

Then('the Belt layer should be {int}') do |expected|
  assert_equal expected, clothing_instance.info.layer
end

Then('the Breastplate layer should be {int}') do |expected|
  assert_equal expected, clothing_instance.info.layer
end

# ── Then: movable ───────────────────────────────────────────────────

Then('the Shoes should be movable') do
  assert clothing_instance.can_move?, 'Expected Shoes to be movable'
end

Then('the Glove should be movable') do
  assert clothing_instance.can_move?, 'Expected Glove to be movable'
end

Then('the Necklace should be movable') do
  assert clothing_instance.can_move?, 'Expected Necklace to be movable'
end

Then('the Belt should be movable') do
  assert clothing_instance.can_move?, 'Expected Belt to be movable'
end

Then('the Breastplate should be movable') do
  assert clothing_instance.can_move?, 'Expected Breastplate to be movable'
end

# ── Then: kind_of GenericClothing ───────────────────────────────────

Then('the Shoes should be a kind of GenericClothing') do
  assert_kind_of Aethyr::Extensions::Objects::GenericClothing, clothing_instance
end

Then('the Glove should be a kind of GenericClothing') do
  assert_kind_of Aethyr::Extensions::Objects::GenericClothing, clothing_instance
end

Then('the Necklace should be a kind of GenericClothing') do
  assert_kind_of Aethyr::Extensions::Objects::GenericClothing, clothing_instance
end

Then('the Belt should be a kind of GenericClothing') do
  assert_kind_of Aethyr::Extensions::Objects::GenericClothing, clothing_instance
end

Then('the Breastplate should be a kind of GenericClothing') do
  assert_kind_of Aethyr::Extensions::Objects::GenericClothing, clothing_instance
end

# ── Then: includes Wearable ─────────────────────────────────────────

Then('the Shoes should include Wearable') do
  assert clothing_instance.class.ancestors.include?(Wearable),
    'Expected Shoes to include Wearable'
end

Then('the Glove should include Wearable') do
  assert clothing_instance.class.ancestors.include?(Wearable),
    'Expected Glove to include Wearable'
end

Then('the Necklace should include Wearable') do
  assert clothing_instance.class.ancestors.include?(Wearable),
    'Expected Necklace to include Wearable'
end

Then('the Belt should include Wearable') do
  assert clothing_instance.class.ancestors.include?(Wearable),
    'Expected Belt to include Wearable'
end

Then('the Breastplate should include Wearable') do
  assert clothing_instance.class.ancestors.include?(Wearable),
    'Expected Breastplate to include Wearable'
end
