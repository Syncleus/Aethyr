# frozen_string_literal: true

###############################################################################
# Step definitions for Parchment game object feature.                         #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module to hold scenario state for Parchment tests.
# ---------------------------------------------------------------------------
module ParchmentWorld
  attr_accessor :parchment
end
World(ParchmentWorld)

# ---------------------------------------------------------------------------
# Lightweight StubManager so that Parchment can be instantiated without the
# full game engine.  Uses `unless defined?` guard to avoid collision with
# other step files that define the same class.
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

Given('I require the Parchment library') do
  $manager ||= StubManager.new
  unless $manager.respond_to?(:existing_goid?)
    def $manager.existing_goid?(_goid)
      false
    end
  end
  require 'aethyr/extensions/objects/parchment'
end

When('a Parchment object is created') do
  $manager = StubManager.new unless $manager.respond_to?(:existing_goid?)
  self.parchment = Aethyr::Extensions::Objects::Parchment.new
end

Then('the Parchment generic should be {string}') do |expected|
  assert_equal expected, parchment.generic
end

Then('the Parchment should be movable') do
  assert parchment.can_move?, 'Expected parchment to be movable'
end

Then('the Parchment short_desc should be {string}') do |expected|
  assert_equal expected, parchment.short_desc
end

Then('the Parchment long_desc should be {string}') do |expected|
  assert_equal expected, parchment.long_desc
end

Then('the Parchment show_in_look should be {string}') do |expected|
  assert_equal expected, parchment.show_in_look
end

Then('the Parchment name should be {string}') do |expected|
  assert_equal expected, parchment.name
end

Then('the Parchment alt_names should include {string}') do |name|
  assert_includes parchment.alt_names, name
end

Then('the Parchment should respond to readable_text') do
  assert parchment.respond_to?(:readable_text),
         'Expected Parchment to respond to :readable_text (from Readable)'
end

Then('the Parchment actions should include {string}') do |action|
  assert parchment.actions.include?(action),
         "Expected actions to include #{action.inspect}"
end

Then('the Parchment readable_text should be nil by default') do
  assert_nil parchment.readable_text
end

Then('the Parchment should be a kind of GameObject') do
  assert_kind_of Aethyr::Core::Objects::GameObject, parchment
end
