# features/step_definitions/skill_steps.rb
# frozen_string_literal: true

###############################################################################
# Step-definitions for the Skill value-object scenarios.                      #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/objects/info/skills/skill'

World(Test::Unit::Assertions)

# --------------------------------------------------------------------------- #
# Setup                                                                       #
# --------------------------------------------------------------------------- #
Given('I require the Skill class') do
  # Verify the class is loadable
  assert(Aethyr::Skills::Skill, 'Skill class could not be loaded')
end

Given('a skill named {string} with {int} xp') do |name, xp|
  @skill = Aethyr::Skills::Skill.new('test_owner', 'skill_1', name, 'A test skill', :trait, xp)
end

# --------------------------------------------------------------------------- #
# Actions                                                                     #
# --------------------------------------------------------------------------- #
When('I add {int} xp to the skill') do |amount|
  @skill.add_xp(amount)
end

# --------------------------------------------------------------------------- #
# Assertions                                                                  #
# --------------------------------------------------------------------------- #
Then('the skill level should be {int}') do |expected|
  assert_equal(expected, @skill.level,
               "Expected level #{expected} but got #{@skill.level}")
end

Then('the skill xp_so_far should be {int}') do |expected|
  assert_equal(expected, @skill.xp_so_far,
               "Expected xp_so_far #{expected} but got #{@skill.xp_so_far}")
end

Then('the skill xp_per_level should be {int}') do |expected|
  assert_equal(expected, @skill.xp_per_level,
               "Expected xp_per_level #{expected} but got #{@skill.xp_per_level}")
end

Then('the skill xp_to_go should be {int}') do |expected|
  assert_equal(expected, @skill.xp_to_go,
               "Expected xp_to_go #{expected} but got #{@skill.xp_to_go}")
end

Then('the skill level_percentage should be {float}') do |expected|
  assert_in_delta(expected, @skill.level_percentage, 0.001,
                  "Expected level_percentage #{expected} but got #{@skill.level_percentage}")
end

Then('the skill xp should be {int}') do |expected|
  assert_equal(expected, @skill.xp,
               "Expected xp #{expected} but got #{@skill.xp}")
end
