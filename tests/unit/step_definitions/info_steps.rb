# frozen_string_literal: true
###############################################################################
# Step definitions for the Info class feature.                                 #
###############################################################################
require 'test/unit/assertions'
require 'aethyr/core/objects/info/info'

World(Test::Unit::Assertions)

###############################################################################
# World module - scenario-scoped state                                         #
###############################################################################
module InfoWorld
  attr_accessor :info_obj, :info_inspect_output, :info_to_s_output
end
World(InfoWorld)

###############################################################################
# Given steps                                                                  #
###############################################################################
Given('I require the Info library') do
  assert defined?(Info),
         'Info class should be present after require'
end

Given('I have an Info object') do
  self.info_obj = Info.new
end

Given('I have an Info object with nested key {string}') do |key|
  self.info_obj = Info.new
  info_obj.set(key, Info.new)
end

###############################################################################
# When steps                                                                   #
###############################################################################
When('I create a new Info object') do
  self.info_obj = Info.new
end

When('I create an Info object from a hash with key {string} and value {string}') do |key, value|
  self.info_obj = Info.new({ key.to_sym => value })
end

When('I set Info key {string} to value {string}') do |key, value|
  info_obj.set(key, value)
end

When('I delete Info key {string}') do |key|
  info_obj.delete(key)
end

When('I call inspect on the Info object') do
  self.info_inspect_output = info_obj.inspect
end

When('I call to_s on the Info object') do
  self.info_to_s_output = info_obj.to_s
end

###############################################################################
# Then steps                                                                   #
###############################################################################
Then('the Info object should not be nil') do
  assert_not_nil(info_obj, 'Expected Info object to exist')
end

Then('the Info get {string} should return {string}') do |key, expected|
  actual = info_obj.get(key)
  assert_equal(expected, actual,
    "Expected Info.get(#{key.inspect}) to return #{expected.inspect} but got #{actual.inspect}")
end

Then('the Info get {string} should return nil') do |key|
  actual = info_obj.get(key)
  assert_nil(actual,
    "Expected Info.get(#{key.inspect}) to return nil but got #{actual.inspect}")
end

Then('the inspect output should start with {string}') do |prefix|
  assert(info_inspect_output.start_with?(prefix),
    "Expected inspect output to start with #{prefix.inspect}, got: #{info_inspect_output.inspect}")
end

Then('the inspect output should contain {string}') do |fragment|
  assert(info_inspect_output.include?(fragment),
    "Expected inspect output to contain #{fragment.inspect}, got: #{info_inspect_output.inspect}")
end

Then('the to_s output should be {string}') do |expected|
  assert_equal(expected, info_to_s_output,
    "Expected to_s to return #{expected.inspect} but got #{info_to_s_output.inspect}")
end
