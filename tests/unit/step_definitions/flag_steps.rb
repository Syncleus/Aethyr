# features/step_definitions/flag_steps.rb
# frozen_string_literal: true

###############################################################################
# Step-definitions for Flag feature.                                          #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/objects/info/flags/flag'

World(Test::Unit::Assertions)

module FlagWorld
  attr_accessor :flag_instance, :flag_negate_result
end
World(FlagWorld)

# --------------------------------------------------------------------------- #
# Construction steps                                                          #
# --------------------------------------------------------------------------- #
Given('I create a Flag with affected {string} and id {int} and name {string} and affect_desc {string} and help_desc {string}') do |affected, id, name, affect_desc, help_desc|
  self.flag_instance = Flag.new(affected, id, name, affect_desc, help_desc)
end

Given('I create a Flag with affected {string} and id {int} and name {string} and affect_desc {string} and help_desc {string} and no flags to negate') do |affected, id, name, affect_desc, help_desc|
  self.flag_instance = Flag.new(affected, id, name, affect_desc, help_desc, nil)
end

Given('I create a Flag with affected {string} and id {int} and name {string} and affect_desc {string} and help_desc {string} and empty flags to negate') do |affected, id, name, affect_desc, help_desc|
  self.flag_instance = Flag.new(affected, id, name, affect_desc, help_desc, [])
end

Given('I create a Flag with affected {string} and id {int} and name {string} and affect_desc {string} and help_desc {string} and flags to negate {string}') do |affected, id, name, affect_desc, help_desc, negate_csv|
  negate_list = negate_csv.split(',')
  self.flag_instance = Flag.new(affected, id, name, affect_desc, help_desc, negate_list)
end

# --------------------------------------------------------------------------- #
# Attribute assertions                                                        #
# --------------------------------------------------------------------------- #
Then('the flag affected should be {string}') do |expected|
  assert_equal(expected, flag_instance.affected)
end

Then('the flag id should be {int}') do |expected|
  assert_equal(expected, flag_instance.id)
end

Then('the flag name should be {string}') do |expected|
  assert_equal(expected, flag_instance.name)
end

Then('the flag affect_desc should be {string}') do |expected|
  assert_equal(expected, flag_instance.affect_desc)
end

Then('the flag help_desc should be {string}') do |expected|
  assert_equal(expected, flag_instance.help_desc)
end

# --------------------------------------------------------------------------- #
# can_see? assertion                                                          #
# --------------------------------------------------------------------------- #
Then('the flag should be visible to any player') do
  assert_equal(true, flag_instance.can_see?("some_player"))
end

# --------------------------------------------------------------------------- #
# negate_flags steps                                                          #
# --------------------------------------------------------------------------- #
When('I negate flags from the list {string}') do |csv|
  @flag_other_flags = csv.split(',')
  flag_instance.negate_flags(@flag_other_flags)
  self.flag_negate_result = @flag_other_flags
end

Then('the negated flags list should be {string}') do |expected_csv|
  expected = expected_csv.split(',')
  assert_equal(expected, flag_negate_result)
end
