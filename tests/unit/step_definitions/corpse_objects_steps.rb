# frozen_string_literal: true
###############################################################################
# Step definitions for Corpse game object feature.                             #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module to hold scenario state for Corpse tests.
# ---------------------------------------------------------------------------
module CorpseWorld
  attr_accessor :corpse, :mock_mobile
end
World(CorpseWorld)

# ---------------------------------------------------------------------------
# Lightweight StubManager so that Corpse can be instantiated without the full
# game engine.  Uses `unless defined?` guard to avoid collision with other
# step files that define the same class.
# ---------------------------------------------------------------------------
unless defined?(StubManager)
  class StubManager
    attr_reader :actions

    def initialize
      @actions = []
    end

    def submit_action(action)
      @actions << action
    end

    def existing_goid?(_goid)
      false
    end
  end
end

# ---------------------------------------------------------------------------
# Lightweight mock mobile for corpse_of tests.
# ---------------------------------------------------------------------------
module CorpseWorld
  class MockMobile
    attr_reader :name, :generic, :alt_names

    def initialize(name, generic, alt_names)
      @name = name
      @generic = generic
      @alt_names = alt_names
    end
  end
end

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

Given('I require the Corpse library') do
  require 'aethyr/core/objects/corpse'
  $manager ||= StubManager.new
  unless $manager.respond_to?(:existing_goid?)
    def $manager.existing_goid?(_goid)
      false
    end
  end
end

When('I create a new Corpse with default arguments') do
  self.corpse = Aethyr::Core::Objects::Corpse.new
end

When('I make the Corpse the corpse of a mobile named {string} with generic {string} and alt_names {string}') do |name, generic, alt_names_csv|
  alt_names = alt_names_csv.split(',').map(&:strip)
  self.mock_mobile = CorpseWorld::MockMobile.new(name, generic, alt_names)
  corpse.corpse_of(mock_mobile)
end

When('I make the Corpse the corpse of a mobile named {string} with generic {string} and no alt_names') do |name, generic|
  self.mock_mobile = CorpseWorld::MockMobile.new(name, generic, nil)
  corpse.corpse_of(mock_mobile)
end

Then('the Corpse generic should be {string}') do |expected|
  assert_equal(expected, corpse.generic)
end

Then('the Corpse should be a kind of GameObject') do
  assert_kind_of(Aethyr::Core::Objects::GameObject, corpse)
end

Then('the Corpse should be movable') do
  assert(corpse.can_move?, 'Expected Corpse to be movable')
end

Then('the Corpse long_desc should be {string}') do |expected|
  assert_equal(expected, corpse.instance_variable_get(:@long_desc))
end

Then('the Corpse should have an expiration time set') do
  assert_not_nil(corpse.info.expiration_time,
                 'Expected Corpse to have an expiration time after initialization')
end

Then('the Corpse should include the Expires module') do
  assert(corpse.class.ancestors.include?(Expires),
         'Expected Corpse to include the Expires module')
end

Then('the Corpse name should be {string}') do |expected|
  assert_equal(expected, corpse.name)
end

Then('the Corpse alt_names should include {string}') do |expected|
  assert(corpse.alt_names.include?(expected),
         "Expected alt_names to include '#{expected}', got: #{corpse.alt_names.inspect}")
end
