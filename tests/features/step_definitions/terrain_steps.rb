# features/step_definitions/terrain_steps.rb
# frozen_string_literal: true

###############################################################################
# Terrain constant validation steps.                                          #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/objects/info/terrain'

World(Test::Unit::Assertions)

Given('I require the Terrain library') do
  assert defined?(Terrain),
         'Terrain module should be present after require'
end

When('I retrieve the GRASSLAND terrain descriptor') do
  @terrain = Terrain::GRASSLAND
end

Then('the room text should be {string}') do |expected|
  assert_equal(expected, @terrain.room_text)
end

Then('the area text should be {string}') do |expected|
  assert_equal(expected, @terrain.area_text)
end

Then('the terrain name should be {string}') do |expected|
  assert_equal(expected, @terrain.name)
end
