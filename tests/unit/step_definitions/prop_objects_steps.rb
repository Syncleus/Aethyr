# frozen_string_literal: true
###############################################################################
# Step definitions for Prop game object feature.                               #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module to hold scenario state for Prop tests.
# ---------------------------------------------------------------------------
module PropWorld
  attr_accessor :prop
end
World(PropWorld)

# ---------------------------------------------------------------------------
# Lightweight StubManager so that Prop can be instantiated without the full
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

Given('I require the Prop library') do
  require 'aethyr/core/objects/prop'
  $manager ||= StubManager.new
  # Ensure the StubManager responds to existing_goid? (needed by GameObject#initialize)
  unless $manager.respond_to?(:existing_goid?)
    def $manager.existing_goid?(_goid)
      false
    end
  end
end

When('I create a new Prop with default arguments') do
  self.prop = Aethyr::Core::Objects::Prop.new
end

When('I create a new Prop with name {string}') do |name|
  self.prop = Aethyr::Core::Objects::Prop.new(nil, nil, name)
end

Then('the Prop generic should be {string}') do |expected|
  assert_equal(expected, prop.generic)
end

Then('the Prop should be a kind of GameObject') do
  assert_kind_of(Aethyr::Core::Objects::GameObject, prop)
end

Then('the Prop name should be {string}') do |expected|
  assert_equal(expected, prop.name)
end

Then('the Prop should have a game object id') do
  assert_not_nil(prop.game_object_id)
  assert(!prop.game_object_id.empty?, 'Expected game_object_id to be non-empty')
end

Then('the Prop should not be movable') do
  assert_equal(false, prop.can_move?)
end

Then('the Prop quantity should be {int}') do |expected|
  assert_equal(expected, prop.quantity)
end
