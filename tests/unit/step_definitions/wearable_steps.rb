# frozen_string_literal: true

###############################################################################
# Step-definitions for Wearable trait scenarios                                #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

###############################################################################
# Helpers                                                                      #
###############################################################################
module WearableWorld
  attr_accessor :wearable_instance

  # Minimal $manager stub so GameObject#initialize succeeds.
  class WearableStubManager
    def existing_goid?(_goid)
      false
    end

    def submit_action(_action); end
  end
end
World(WearableWorld)

###############################################################################
# Steps                                                                        #
###############################################################################

Given('I require the Wearable test dependencies') do
  $manager ||= WearableWorld::WearableStubManager.new
  require 'aethyr/extensions/objects/clothing_items'
end

When('I create a wearable test object') do
  $manager = WearableWorld::WearableStubManager.new
  # Shoes includes Wearable via GenericClothing; its initialize sets
  # info.position = :feet and info.layer = 2 through the Wearable chain,
  # then overrides position to :feet in its own initialize.
  self.wearable_instance = Aethyr::Extensions::Objects::Shoes.new
end

When('I set the wearable info position to nil') do
  wearable_instance.info.position = nil
end

When('I set the wearable info layer to nil') do
  wearable_instance.info.layer = nil
end

# ── Assertions ─────────────────────────────────────────────────────

Then('the wearable position should be :feet') do
  assert_equal :feet, wearable_instance.position
end

Then('the wearable position should be nil') do
  assert_nil wearable_instance.position
end

Then('the wearable layer should be {int}') do |expected|
  assert_equal expected, wearable_instance.layer
end
