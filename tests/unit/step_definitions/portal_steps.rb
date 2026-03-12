# frozen_string_literal: true
###############################################################################
# Step definitions for Portal game object feature.                            #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module – keeps scenario state isolated per scenario.
# ---------------------------------------------------------------------------
module PortalObjectWorld
  attr_accessor :portal_obj, :portal_message_result
end
World(PortalObjectWorld)

# ---------------------------------------------------------------------------
# Lightweight StubManager so Portal can be instantiated without the full
# game engine.
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
# Lightweight mock player with name and pronoun support.
# ---------------------------------------------------------------------------
class PortalMockPlayer
  attr_accessor :name

  def initialize(name = "Tester")
    @name = name
  end

  # Simplified pronoun that returns known values for testing.
  def pronoun(type = nil)
    if type == :possessive
      "her"
    else
      "she"
    end
  end
end

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

Given('I require the Portal library') do
  require 'aethyr/core/objects/portal'
  $manager ||= StubManager.new
  unless $manager.respond_to?(:existing_goid?)
    def $manager.existing_goid?(_goid)
      false
    end
  end
end

# --- Portal construction helpers ---

When('I create a new Portal with default arguments') do
  self.portal_obj = Aethyr::Core::Objects::Portal.new
end

Given('a Portal with a custom entrance_message {string}') do |msg|
  self.portal_obj = Aethyr::Core::Objects::Portal.new
  portal_obj.info.entrance_message = msg
end

Given('a Portal with no custom entrance_message named {string}') do |name|
  self.portal_obj = Aethyr::Core::Objects::Portal.new
  portal_obj.instance_variable_set(:@name, name)
end

Given('a Portal with a custom exit_message {string}') do |msg|
  self.portal_obj = Aethyr::Core::Objects::Portal.new
  portal_obj.info.exit_message = msg
end

Given('a Portal with no custom exit_message named {string}') do |name|
  self.portal_obj = Aethyr::Core::Objects::Portal.new
  portal_obj.instance_variable_set(:@name, name)
end

Given('a Portal with a custom portal_message {string}') do |msg|
  self.portal_obj = Aethyr::Core::Objects::Portal.new
  portal_obj.info.portal_message = msg
end

Given('a Portal with no custom portal_message named {string}') do |name|
  self.portal_obj = Aethyr::Core::Objects::Portal.new
  portal_obj.instance_variable_set(:@name, name)
end

Given('a Portal with long_desc {string}') do |desc|
  self.portal_obj = Aethyr::Core::Objects::Portal.new
  portal_obj.instance_variable_set(:@long_desc, desc)
end

# --- Constructor assertions ---

Then('the Portal generic should be {string}') do |expected|
  assert_equal(expected, portal_obj.generic)
end

Then('the Portal article should be {string}') do |expected|
  assert_equal(expected, portal_obj.article)
end

Then('the Portal should not be visible') do
  assert_equal(false, portal_obj.visible)
end

Then('the Portal show_in_look should be {string}') do |expected|
  assert_equal(expected, portal_obj.show_in_look)
end

Then('the Portal should be a kind of Exit') do
  assert_kind_of(Aethyr::Core::Objects::Exit, portal_obj)
end

# --- entrance_message invocations ---

When('I call entrance_message with player {string}') do |name|
  player = PortalMockPlayer.new(name)
  self.portal_message_result = portal_obj.entrance_message(player)
end

When('I call entrance_message with player {string} and action {string}') do |name, action|
  player = PortalMockPlayer.new(name)
  self.portal_message_result = portal_obj.entrance_message(player, action)
end

# --- exit_message invocations ---

When('I call exit_message with player {string}') do |name|
  player = PortalMockPlayer.new(name)
  self.portal_message_result = portal_obj.exit_message(player)
end

When('I call exit_message with player {string} and action {string}') do |name, action|
  player = PortalMockPlayer.new(name)
  self.portal_message_result = portal_obj.exit_message(player, action)
end

# --- portal_message invocations ---

When('I call portal_message with player {string}') do |name|
  player = PortalMockPlayer.new(name)
  self.portal_message_result = portal_obj.portal_message(player)
end

When('I call portal_message with player {string} and action {string}') do |name, action|
  player = PortalMockPlayer.new(name)
  self.portal_message_result = portal_obj.portal_message(player, action)
end

# --- peer invocation ---

When('I call peer on the Portal') do
  self.portal_message_result = portal_obj.peer
end

# --- Result assertion ---

Then('the Portal message result should be {string}') do |expected|
  assert_equal(expected, portal_message_result)
end
