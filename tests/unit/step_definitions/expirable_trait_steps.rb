# frozen_string_literal: true

###############################################################################
# Step definitions for the Expires trait feature.                              #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'
require 'aethyr/core/objects/traits/expires'

World(Test::Unit::Assertions)

###############################################################################
# Minimal base class that provides the interface Expires expects (info, run,  #
# initialize) without pulling in the full GameObject dependency tree.          #
###############################################################################
module ExpirableWorld
  class ExpirableTestBase
    attr_accessor :info

    def initialize
      @info = OpenStruct.new
    end

    def run; end
  end

  class ExpirableTestObject < ExpirableTestBase
    include Expires
  end

  attr_accessor :expirable_object, :expirable_error
end
World(ExpirableWorld)

###############################################################################
# Given steps                                                                  #
###############################################################################
Given('I have an expirable test object') do
  self.expirable_object = ExpirableWorld::ExpirableTestObject.new
end

Given('the expirable object has a past expiration time') do
  # Set expiration_time to a moment in the past so the next run triggers expire
  expirable_object.info.expiration_time = (Time.now.to_i - 100)
end

###############################################################################
# When steps                                                                   #
###############################################################################
When('I set the expirable object to expire in {int} seconds') do |seconds|
  expirable_object.expire_in(seconds)
end

When('I run the expirable object') do
  expirable_object.run
end

When('I run the expired object expecting failure') do
  self.expirable_error = nil
  begin
    expirable_object.run
  rescue RuntimeError => e
    self.expirable_error = e
  end
end

###############################################################################
# Then steps                                                                   #
###############################################################################
Then('the expirable object should exist') do
  assert_not_nil(expirable_object, 'Expected expirable object to be created')
end

Then('the expirable object info should be present') do
  assert_not_nil(expirable_object.info,
                 'Expected info to be initialised by Expires#initialize')
end

Then('the expirable expiration time should be approximately {int} seconds from now') do |seconds|
  expected = (Time.now + seconds).to_i
  actual   = expirable_object.info.expiration_time
  # Allow a 2-second tolerance for test execution time
  assert((expected - actual).abs <= 2,
         "Expected expiration_time ~#{expected}, got #{actual}")
end

Then('the expirable object should not raise') do
  # If we got here without an exception the step passes.
  assert(true)
end

Then('the expirable expire error should be raised') do
  assert_not_nil(expirable_error, 'Expected a RuntimeError but none was raised')
  assert_equal('expire is not yet properly implemented', expirable_error.message)
end
