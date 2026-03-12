# frozen_string_literal: true

###############################################################################
# Step-definitions for weapon object scenarios (Sword, etc.)                   #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

###############################################################################
# Minimal $manager stub – GameObject#initialize calls                          #
# $manager.existing_goid? to guarantee GOID uniqueness.                        #
###############################################################################
module WeaponObjectWorld
  attr_accessor :sword_instance

  class WeaponStubManager
    def existing_goid?(_goid)
      false
    end

    def submit_action(action)
      # no-op
    end
  end
end
World(WeaponObjectWorld)

###############################################################################
# Steps                                                                        #
###############################################################################

Given('I require the Sword weapon library') do
  # Ensure $manager is available before requiring the library, since
  # some code paths reference it at class-load time.
  $manager ||= WeaponObjectWorld::WeaponStubManager.new
  require 'aethyr/extensions/objects/sword'
end

When('I create a new Sword weapon object') do
  $manager ||= WeaponObjectWorld::WeaponStubManager.new
  self.sword_instance = Aethyr::Extensions::Objects::Sword.new
end

Then('the Sword generic should be {string}') do |expected|
  assert_equal expected, sword_instance.generic
end

Then('the Sword weapon_type should be :sword') do
  assert_equal :sword, sword_instance.info.weapon_type
end

Then('the Sword attack should be {int}') do |expected|
  assert_equal expected, sword_instance.info.attack
end

Then('the Sword defense should be {int}') do |expected|
  assert_equal expected, sword_instance.info.defense
end

Then('the Sword position should be :wield') do
  assert_equal :wield, sword_instance.info.position
end

Then('the Sword should be movable') do
  assert sword_instance.can_move?, 'Expected Sword to be movable'
end

Then('the Sword should be a kind of Weapon') do
  assert_kind_of Aethyr::Core::Objects::Weapon, sword_instance
end

Then('the Sword layer should be {int}') do |expected|
  assert_equal expected, sword_instance.info.layer
end
