# frozen_string_literal: true
###############################################################################
# Step-definitions for elemental flag classes in                               #
#   lib/aethyr/extensions/flags/elements.rb                                    #
###############################################################################

require 'test/unit/assertions'
require 'aethyr/extensions/flags/elements'

World(Test::Unit::Assertions)

module ElementsWorld
  attr_accessor :element_flag_instance
end
World(ElementsWorld)

###############################################################################
# Given – construct each elemental flag                                        #
###############################################################################

Given('I create a PlusWater element flag with affected {string}') do |affected|
  self.element_flag_instance = PlusWater.new(affected)
end

Given('I create a MinusWater element flag with affected {string}') do |affected|
  self.element_flag_instance = MinusWater.new(affected)
end

Given('I create a PlusEarth element flag with affected {string}') do |affected|
  self.element_flag_instance = PlusEarth.new(affected)
end

Given('I create a MinusEarth element flag with affected {string}') do |affected|
  self.element_flag_instance = MinusEarth.new(affected)
end

Given('I create a PlusFire element flag with affected {string}') do |affected|
  self.element_flag_instance = PlusFire.new(affected)
end

Given('I create a MinusFire element flag with affected {string}') do |affected|
  self.element_flag_instance = MinusFire.new(affected)
end

Given('I create a PlusAir element flag with affected {string}') do |affected|
  self.element_flag_instance = PlusAir.new(affected)
end

Given('I create a MinusAir element flag with affected {string}') do |affected|
  self.element_flag_instance = MinusAir.new(affected)
end

###############################################################################
# Then – attribute assertions                                                  #
###############################################################################

Then('the element flag id should be {string}') do |expected|
  expected_sym = expected.sub(/^:/, '').to_sym
  assert_equal(expected_sym, element_flag_instance.id)
end

Then('the element flag name should be {string}') do |expected|
  assert_equal(expected, element_flag_instance.name)
end

Then('the element flag affect_desc should contain {string}') do |expected|
  assert(element_flag_instance.affect_desc.include?(expected),
         "Expected affect_desc to contain '#{expected}' but got: #{element_flag_instance.affect_desc.inspect}")
end

Then('the element flag help_desc should contain {string}') do |expected|
  assert(element_flag_instance.help_desc.include?(expected),
         "Expected help_desc to contain '#{expected}' but got: #{element_flag_instance.help_desc.inspect}")
end

Then('the element flag affected should be {string}') do |expected|
  assert_equal(expected, element_flag_instance.affected)
end
