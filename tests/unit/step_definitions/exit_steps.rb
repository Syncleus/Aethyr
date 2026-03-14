# frozen_string_literal: true
###############################################################################
# Step definitions for Exit game object feature.                              #
#                                                                             #
# Exercises lib/aethyr/core/objects/exit.rb – especially the #peer method.    #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module – scenario-scoped state.
# ---------------------------------------------------------------------------
module ExitObjectWorld
  attr_accessor :exit_obj, :exit_peer_result
end
World(ExitObjectWorld)

# ---------------------------------------------------------------------------
# Stub manager – supports configurable #find results keyed by argument.
# ---------------------------------------------------------------------------
unless defined?(ExitStubManager)
  class ExitStubManager
    attr_accessor :find_map

    def initialize
      @find_map = {}
    end

    def existing_goid?(_goid)
      false
    end

    def find(id, *_rest)
      @find_map[id]
    end
  end
end

# ---------------------------------------------------------------------------
# Lightweight mock room returned by the stub manager.
# ---------------------------------------------------------------------------
class ExitMockRoom
  attr_reader :name

  def initialize(name)
    @name = name
  end
end

# ---------------------------------------------------------------------------
# Before hook – ensure $manager is our stub for every scenario.
# ---------------------------------------------------------------------------
Before('@exit_test') do
  $manager = ExitStubManager.new
end

###############################################################################
# Given steps                                                                 #
###############################################################################

Given('I require the Exit library') do
  require 'aethyr/core/objects/exit'
  unless $manager.is_a?(ExitStubManager)
    $manager = ExitStubManager.new
  end
  $manager.find_map = {}
end

Given('a new Exit with no exit_room') do
  self.exit_obj = Aethyr::Core::Objects::Exit.new(nil)
end

Given('a new Exit with exit_room {string}') do |room_id|
  self.exit_obj = Aethyr::Core::Objects::Exit.new(room_id)
end

Given('the exit manager returns nil for {string}') do |room_id|
  $manager.find_map[room_id] = nil
end

Given('the exit manager returns a mock room named {string} for {string}') do |name, room_id|
  $manager.find_map[room_id] = ExitMockRoom.new(name)
end

###############################################################################
# When steps                                                                  #
###############################################################################

When('I create a new Exit with no arguments') do
  self.exit_obj = Aethyr::Core::Objects::Exit.new
end

When('I create a new Exit with exit_room {string}') do |room_id|
  self.exit_obj = Aethyr::Core::Objects::Exit.new(room_id)
end

When('I call peer on the exit') do
  self.exit_peer_result = exit_obj.peer
end

###############################################################################
# Then steps                                                                  #
###############################################################################

Then('the exit generic should be {string}') do |expected|
  assert_equal expected, exit_obj.instance_variable_get(:@generic)
end

Then('the exit article should be {string}') do |expected|
  assert_equal expected, exit_obj.instance_variable_get(:@article)
end

Then('the exit alt_names should contain {string}') do |expected|
  alt_names = exit_obj.instance_variable_get(:@alt_names)
  assert alt_names.include?(expected),
    "Expected alt_names to contain '#{expected}', got: #{alt_names.inspect}"
end

Then('the exit exit_room should be nil') do
  assert_nil exit_obj.exit_room
end

Then('the exit exit_room should be {string}') do |expected|
  assert_equal expected, exit_obj.exit_room
end

Then('the exit peer result should be {string}') do |expected|
  assert_equal expected, exit_peer_result
end
