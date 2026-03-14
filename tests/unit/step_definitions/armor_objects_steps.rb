# frozen_string_literal: true

###############################################################################
# Step-definitions for Armor object scenarios                                  #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

###############################################################################
# Minimal $manager stub – GameObject#initialize calls                          #
# $manager.existing_goid? to guarantee GOID uniqueness.                        #
###############################################################################
module ArmorObjectWorld
  attr_accessor :armor_instance

  class ArmorStubManager
    def existing_goid?(_goid)
      false
    end

    def submit_action(action)
      # no-op
    end
  end
end
World(ArmorObjectWorld)

###############################################################################
# Steps                                                                        #
###############################################################################

Given('I require the Armor library') do
  $manager ||= ArmorObjectWorld::ArmorStubManager.new
  require 'aethyr/core/objects/armor'
end

When('I create a new Armor object') do
  $manager ||= ArmorObjectWorld::ArmorStubManager.new
  self.armor_instance = Aethyr::Core::Objects::Armor.new
end

Then('the Armor generic should be {string}') do |expected|
  assert_equal expected, armor_instance.generic
end

Then('the Armor article should be {string}') do |expected|
  assert_equal expected, armor_instance.article
end

Then('the Armor should be movable') do
  assert armor_instance.can_move?, 'Expected Armor to be movable'
end

Then('the Armor condition should be {int}') do |expected|
  assert_equal expected, armor_instance.instance_variable_get(:@condition)
end

Then('the Armor layer should be {int}') do |expected|
  assert_equal expected, armor_instance.info.layer
end

Then('the Armor position should be :torso') do
  assert_equal :torso, armor_instance.info.position
end

Then('the Armor should be a kind of GameObject') do
  assert_kind_of Aethyr::Core::Objects::GameObject, armor_instance
end
