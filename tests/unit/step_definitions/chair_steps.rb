# frozen_string_literal: true
###############################################################################
# Step definitions for Chair game object feature.                              #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module to hold scenario state for Chair tests.
# ---------------------------------------------------------------------------
module ChairWorld
  attr_accessor :chair_instance
end
World(ChairWorld)

# ---------------------------------------------------------------------------
# Lightweight StubManager so that Chair can be instantiated without the full
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
# Steps
# ---------------------------------------------------------------------------

Given('I require the Chair library') do
  $manager ||= StubManager.new
  unless $manager.respond_to?(:existing_goid?)
    def $manager.existing_goid?(_goid)
      false
    end
  end
  require 'aethyr/extensions/objects/chair'
end

When('I create a new Chair with default arguments') do
  self.chair_instance = Aethyr::Extensions::Objects::Chair.new
end

Then('the Chair name should be {string}') do |expected|
  assert_equal(expected, chair_instance.name)
end

Then('the Chair generic should be {string}') do |expected|
  assert_equal(expected, chair_instance.generic)
end

Then('the Chair should not be movable') do
  assert_equal(false, chair_instance.movable)
end

Then('the Chair should be a kind of GameObject') do
  assert_kind_of(Aethyr::Core::Objects::GameObject, chair_instance)
end

Then('the Chair should be sittable') do
  assert(chair_instance.respond_to?(:sittable?) && chair_instance.sittable?,
         'Expected Chair to be sittable')
end
