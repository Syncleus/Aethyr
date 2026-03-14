# frozen_string_literal: true

###############################################################################
# Step-definitions for Dagger weapon object scenarios                          #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

###############################################################################
# Minimal $manager stub – GameObject#initialize calls                          #
# $manager.existing_goid? to guarantee GOID uniqueness.                        #
###############################################################################
module DaggerObjectWorld
  attr_accessor :dagger_instance

  class DaggerStubManager
    def existing_goid?(_goid)
      false
    end

    def submit_action(action)
      # no-op
    end
  end
end
World(DaggerObjectWorld)

###############################################################################
# Steps                                                                        #
###############################################################################

Given('I require the Dagger weapon library') do
  $manager ||= DaggerObjectWorld::DaggerStubManager.new
  require 'aethyr/extensions/objects/dagger'
end

When('I create a new Dagger weapon object') do
  $manager ||= DaggerObjectWorld::DaggerStubManager.new
  self.dagger_instance = Aethyr::Extensions::Objects::Dagger.new
end

Then('the Dagger generic should be {string}') do |expected|
  assert_equal expected, dagger_instance.generic
end

Then('the Dagger weapon_type should be :dagger') do
  assert_equal :dagger, dagger_instance.info.weapon_type
end

Then('the Dagger attack should be {int}') do |expected|
  assert_equal expected, dagger_instance.info.attack
end

Then('the Dagger defense should be {int}') do |expected|
  assert_equal expected, dagger_instance.info.defense
end

Then('the Dagger position should be :wield') do
  assert_equal :wield, dagger_instance.info.position
end

Then('the Dagger should be movable') do
  assert dagger_instance.can_move?, 'Expected Dagger to be movable'
end

Then('the Dagger should be a kind of Weapon') do
  assert_kind_of Aethyr::Core::Objects::Weapon, dagger_instance
end

Then('the Dagger layer should be {int}') do |expected|
  assert_equal expected, dagger_instance.info.layer
end
