# frozen_string_literal: true

###############################################################################
# Step definitions for the Sittable trait feature.                             #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/objects/traits/sittable'

World(Test::Unit::Assertions)

###############################################################################
# Minimal base class that provides the interface Sittable expects.             #
###############################################################################
module SittableWorld
  class SittableTestBase
    def initialize
      # intentionally empty – provides a super target for Sittable#initialize
    end
  end

  class SittableTestObject < SittableTestBase
    include Sittable
  end

  # Minimal player stub with a goid attribute.
  class MockSittablePlayer
    attr_reader :goid

    def initialize(goid)
      @goid = goid
    end
  end

  attr_accessor :sittable_object, :sittable_player, :sittable_player2
end
World(SittableWorld)

###############################################################################
# Given steps                                                                  #
###############################################################################
Given('I have a sittable test object') do
  self.sittable_object = SittableWorld::SittableTestObject.new
end

Given('a mock player with goid {string}') do |goid|
  self.sittable_player = SittableWorld::MockSittablePlayer.new(goid)
end

Given('a second mock player with goid {string}') do |goid|
  self.sittable_player2 = SittableWorld::MockSittablePlayer.new(goid)
end

Given('the mock player is already sitting on the sittable object') do
  sittable_object.sat_on_by(sittable_player)
end

###############################################################################
# When steps                                                                   #
###############################################################################
When('the mock player sits on the sittable object') do
  sittable_object.sat_on_by(sittable_player)
end

When('the mock player evacuates the sittable object') do
  sittable_object.evacuated_by(sittable_player)
end

###############################################################################
# Then steps                                                                   #
###############################################################################
Then('the sittable object should exist') do
  assert_not_nil(sittable_object, 'Expected sittable object to be created')
end

Then('the sittable object should report sittable as true') do
  assert_equal(true, sittable_object.sittable?,
               'Expected sittable? to return true')
end

Then('the sittable object should not be occupied') do
  assert_equal(false, sittable_object.occupied?,
               'Expected occupied? to return false')
end

Then('the sittable object should be occupied') do
  assert_equal(true, sittable_object.occupied?,
               'Expected occupied? to return true')
end

Then('the sittable object should have room') do
  assert_equal(true, sittable_object.has_room?,
               'Expected has_room? to return true')
end

Then('the sittable object should not have room') do
  assert_equal(false, sittable_object.has_room?,
               'Expected has_room? to return false (occupancy = 1, 1 seated)')
end

Then('the sittable object occupants should be empty') do
  assert(sittable_object.occupants.empty?,
         'Expected occupants to be empty')
end

Then('the sittable object occupants should include {string}') do |goid|
  assert(sittable_object.occupants.include?(goid),
         "Expected occupants to include '#{goid}'")
end

Then('the sittable object occupants should not include {string}') do |goid|
  assert(!sittable_object.occupants.include?(goid),
         "Expected occupants NOT to include '#{goid}'")
end

Then('the sittable object should report occupied by the mock player') do
  assert_equal(true, sittable_object.occupied_by?(sittable_player),
               'Expected occupied_by? to return true for the mock player')
end

Then('the sittable object should not report occupied by the mock player') do
  assert_equal(false, sittable_object.occupied_by?(sittable_player),
               'Expected occupied_by? to return false for the mock player')
end

Then('the sittable object should not report occupied by the second mock player') do
  assert_equal(false, sittable_object.occupied_by?(sittable_player2),
               'Expected occupied_by? to return false for the second mock player')
end
