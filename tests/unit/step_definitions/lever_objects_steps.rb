# frozen_string_literal: true
###############################################################################
# Step definitions for Lever game object feature.                              #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module to hold scenario state for Lever tests.
# ---------------------------------------------------------------------------
module LeverWorld
  attr_accessor :lever_instance
end
World(LeverWorld)

# ---------------------------------------------------------------------------
# Lightweight StubManager so that Lever can be instantiated without the full
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

Given('I require the Lever library') do
  $manager ||= StubManager.new
  unless $manager.respond_to?(:existing_goid?)
    def $manager.existing_goid?(_goid)
      false
    end
  end
  require 'aethyr/extensions/objects/lever'
end

When('I create a new Lever with default arguments') do
  self.lever_instance = Aethyr::Extensions::Objects::Lever.new
end

Then('the Lever name should be {string}') do |expected|
  assert_equal(expected, lever_instance.name)
end

Then('the Lever generic should be {string}') do |expected|
  assert_equal(expected, lever_instance.generic)
end

Then('the Lever short_desc should be {string}') do |expected|
  assert_equal(expected, lever_instance.short_desc)
end

Then('the Lever should be a kind of GameObject') do
  assert_kind_of(Aethyr::Core::Objects::GameObject, lever_instance)
end

Then('the Lever long_desc should describe a 2 foot lever with a grip') do
  expected = 'A lever, about 2 feet long with a grip situated near the top, just begging to be pulled.'
  assert_equal(expected, lever_instance.long_desc)
end

Then('the Lever actions should include {string}') do |expected|
  assert(lever_instance.actions.include?(expected),
         "Expected actions to include '#{expected}', got: #{lever_instance.actions.inspect}")
end
