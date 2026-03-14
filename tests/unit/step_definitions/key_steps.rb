# frozen_string_literal: true
###############################################################################
# Step definitions for Key game object feature.                                #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module to hold scenario state for Key tests.
# ---------------------------------------------------------------------------
module KeyWorld
  attr_accessor :key_instance
end
World(KeyWorld)

# ---------------------------------------------------------------------------
# Lightweight StubManager so that Key can be instantiated without the full
# game engine.  Uses `unless defined?` guard to avoid collision with other
# step files that define the same class.
# ---------------------------------------------------------------------------
unless defined?(KeyStubManager)
  class KeyStubManager
    def existing_goid?(_goid)
      false
    end
  end
end

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

Given('I require the Key library') do
  $manager ||= KeyStubManager.new
  unless $manager.respond_to?(:existing_goid?)
    def $manager.existing_goid?(_goid)
      false
    end
  end
  require 'aethyr/extensions/objects/key'
end

When('I create a new Key with default arguments') do
  self.key_instance = Aethyr::Extensions::Objects::Key.new
end

Then('the key generic should be {string}') do |expected|
  assert_equal(expected, key_instance.generic)
end

Then('the key movable should be true') do
  assert_equal(true, key_instance.movable)
end

Then('the key short_desc should be {string}') do |expected|
  assert_equal(expected, key_instance.short_desc)
end

Then('the key should be a kind of GameObject') do
  assert_kind_of(Aethyr::Core::Objects::GameObject, key_instance)
end
