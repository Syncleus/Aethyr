# frozen_string_literal: true
###############################################################################
# Step definitions for IntegrationMockRoom coverage.                           #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

###############################################################################
# Ensure the Aethyr::Core::Objects::Room constant exists for is_a? checks.     #
###############################################################################
unless defined?(Aethyr::Core::Objects::Room)
  module Aethyr
    module Core
      module Objects
        class Room; end
      end
    end
  end
end

###############################################################################
# Require the class under test.                                                #
###############################################################################
require_relative '../../../lib/aethyr/core/objects/integration_mock_room'

###############################################################################
# World module – scenario-scoped state with imr_ prefix.                       #
###############################################################################
module ImrTestWorld
  attr_accessor :imr_room, :imr_result
end
World(ImrTestWorld)

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('I create an imr with goid {string}') do |goid|
  self.imr_room = IntegrationMockRoom.new(goid)
end

Given('I create an imr with goid {string} name {string} coordinates {int} and {int} and container {string}') do |goid, name, x, y, container|
  self.imr_room = IntegrationMockRoom.new(goid, name, [x, y], container)
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('I marshal_load the imr with symbol keys goid {string} name {string} coordinates {int} and {int} and container {string}') do |goid, name, x, y, container|
  self.imr_room.marshal_load({ goid: goid, name: name, coordinates: [x, y], container_goid: container })
end

When('I marshal_load the imr with string keys goid {string} name {string} coordinates {int} and {int} and container {string}') do |goid, name, x, y, container|
  self.imr_room.marshal_load({ 'goid' => goid, 'name' => name, 'coordinates' => [x, y], 'container_goid' => container })
end

When('I marshal_load the imr with minimal data goid {string} and name {string}') do |goid, name|
  self.imr_room.marshal_load({ goid: goid, name: name })
end

When('I rehydrate the imr with symbol keys goid {string} name {string} coordinates {int} and {int} and container {string}') do |goid, name, x, y, container|
  self.imr_result = self.imr_room.rehydrate({ goid: goid, name: name, coordinates: [x, y], container_goid: container })
end

When('I rehydrate the imr with string keys goid {string} name {string} coordinates {int} and {int} and container {string}') do |goid, name, x, y, container|
  self.imr_room.rehydrate({ 'goid' => goid, 'name' => name, 'coordinates' => [x, y], 'container_goid' => container })
end

When('I rehydrate the imr with nil data') do
  self.imr_result = self.imr_room.rehydrate(nil)
end

When('I rehydrate the imr with empty data') do
  self.imr_room.rehydrate({})
end

When('I round-trip the imr through marshal_dump and marshal_load') do
  data = self.imr_room.marshal_dump
  self.imr_room = IntegrationMockRoom.new('tmp')
  self.imr_room.marshal_load(data)
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the imr goid should be {string}') do |expected|
  assert_equal expected, self.imr_room.goid
end

Then('the imr name should be {string}') do |expected|
  assert_equal expected, self.imr_room.name
end

Then('the imr coordinates should be {int} and {int}') do |x, y|
  assert_equal [x, y], self.imr_room.coordinates
end

Then('the imr container_goid should be {string}') do |expected|
  assert_equal expected, self.imr_room.container_goid
end

Then('the imr game_object_id should equal its goid') do
  assert_equal self.imr_room.goid, self.imr_room.game_object_id
end

Then('the imr admin should be false') do
  assert_equal false, self.imr_room.admin
end

Then('the imr room should be {string}') do |expected|
  assert_equal expected, self.imr_room.room
end

Then('the imr container should be {string}') do |expected|
  assert_equal expected, self.imr_room.container
end

Then('the imr is_a Room should be true') do
  assert_equal true, self.imr_room.is_a?(Aethyr::Core::Objects::Room)
end

Then('the imr is_a String should be false') do
  assert_equal false, self.imr_room.is_a?(String)
end

Then('the imr marshal_dump should contain all attributes') do
  dump = self.imr_room.marshal_dump
  assert_equal self.imr_room.goid, dump[:goid]
  assert_equal self.imr_room.name, dump[:name]
  assert_equal self.imr_room.coordinates, dump[:coordinates]
  assert_equal self.imr_room.container_goid, dump[:container_goid]
end

Then('the imr rehydrate result should be the same object') do
  assert_same self.imr_room, self.imr_result
end
