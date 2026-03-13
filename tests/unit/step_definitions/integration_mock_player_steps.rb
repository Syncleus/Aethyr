# frozen_string_literal: true
###############################################################################
# Step definitions for IntegrationMockPlayer coverage.                         #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'

World(Test::Unit::Assertions)

###############################################################################
# Ensure the Aethyr::Core::Objects::Player constant exists for is_a? checks.   #
###############################################################################
unless defined?(Aethyr::Core::Objects::Player)
  module Aethyr
    module Core
      module Objects
        class Player; end
      end
    end
  end
end

###############################################################################
# Require the class under test.                                                #
###############################################################################
require_relative '../../../lib/aethyr/core/objects/integration_mock_player'

###############################################################################
# World module – scenario-scoped state with imp_ prefix.                       #
###############################################################################
module ImpTestWorld
  attr_accessor :imp_player, :imp_result
end
World(ImpTestWorld)

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('I create an imp with goid {string}') do |goid|
  self.imp_player = IntegrationMockPlayer.new(goid)
end

Given('I create an imp with goid {string} name {string} and container {string}') do |goid, name, container|
  self.imp_player = IntegrationMockPlayer.new(goid, name, container)
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('I marshal_load the imp with symbol keys goid {string} name {string} container {string} and info') do |goid, name, container|
  self.imp_player.marshal_load({ goid: goid, name: name, container_goid: container, info: OpenStruct.new })
end

When('I marshal_load the imp with string keys goid {string} name {string} container {string} and info') do |goid, name, container|
  self.imp_player.marshal_load({ 'goid' => goid, 'name' => name, 'container_goid' => container, 'info' => OpenStruct.new })
end

When('I marshal_load the imp with minimal data goid {string} and name {string}') do |goid, name|
  self.imp_player.marshal_load({ goid: goid, name: name })
end

When('I rehydrate the imp with symbol keys goid {string} name {string} container {string} and info') do |goid, name, container|
  self.imp_result = self.imp_player.rehydrate({ goid: goid, name: name, container_goid: container, info: OpenStruct.new })
end

When('I rehydrate the imp with string keys goid {string} name {string} container {string} and info') do |goid, name, container|
  self.imp_result = self.imp_player.rehydrate({ 'goid' => goid, 'name' => name, 'container_goid' => container, 'info' => OpenStruct.new })
end

When('I rehydrate the imp with nil data') do
  self.imp_result = self.imp_player.rehydrate(nil)
end

When('I rehydrate the imp with empty data') do
  self.imp_result = self.imp_player.rehydrate({})
end

When('I round-trip the imp through marshal_dump and marshal_load') do
  data = self.imp_player.marshal_dump
  self.imp_player = IntegrationMockPlayer.new('tmp')
  self.imp_player.marshal_load(data)
end

When('I set the imp info to a custom OpenStruct') do
  self.imp_player.info = OpenStruct.new(name: 'custom')
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the imp goid should be {string}') do |expected|
  assert_equal expected, self.imp_player.goid
end

Then('the imp name should be {string}') do |expected|
  assert_equal expected, self.imp_player.name
end

Then('the imp container_goid should be {string}') do |expected|
  assert_equal expected, self.imp_player.container_goid
end

Then('the imp container_goid should be nil') do
  assert_nil self.imp_player.container_goid
end

Then('the imp info should be an OpenStruct') do
  assert_instance_of OpenStruct, self.imp_player.info
end

Then('the imp game_object_id should equal its goid') do
  assert_equal self.imp_player.goid, self.imp_player.game_object_id
end

Then('the imp admin should be false') do
  assert_equal false, self.imp_player.admin
end

Then('the imp room should be {string}') do |expected|
  assert_equal expected, self.imp_player.room
end

Then('the imp container should be {string}') do |expected|
  assert_equal expected, self.imp_player.container
end

Then('the imp is_a Player should be true') do
  assert_equal true, self.imp_player.is_a?(Aethyr::Core::Objects::Player)
end

Then('the imp is_a String should be false') do
  assert_equal false, self.imp_player.is_a?(String)
end

Then('the imp marshal_dump should contain all attributes') do
  dump = self.imp_player.marshal_dump
  assert_equal self.imp_player.goid, dump[:goid]
  assert_equal self.imp_player.name, dump[:name]
  assert_equal self.imp_player.container_goid, dump[:container_goid]
  assert_equal self.imp_player.info, dump[:info]
end

Then('the imp rehydrate result should be the same object') do
  assert_same self.imp_player, self.imp_result
end

Then('calling output on the imp should not raise') do
  assert_nothing_raised { self.imp_player.output('test message') }
end

Then('calling quit on the imp should not raise') do
  assert_nothing_raised { self.imp_player.quit }
end

Then('the imp info name should be {string}') do |expected|
  assert_equal expected, self.imp_player.info.name
end
