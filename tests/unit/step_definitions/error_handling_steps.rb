# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step-definitions for Aethyr custom error handling feature
#
# Exercises every line in lib/aethyr/core/errors.rb by loading the module,
# instantiating each error class, and raising/rescuing each one.
# -----------------------------------------------------------------------------
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module to hold scenario state for error-handling steps
# ---------------------------------------------------------------------------
module AethyrErrorWorld
  attr_accessor :aethyr_error, :aethyr_rescued_error
end
World(AethyrErrorWorld)

# ---------------------------------------------------------------------------
# Steps – all prefixed with "Aethyr error" to avoid collisions
# ---------------------------------------------------------------------------

Given('I require the Aethyr error library') do
  require 'aethyr/core/errors'
end

Then('the Aethyr error module MUDError should be defined') do
  assert(Object.const_defined?(:MUDError),
         'Expected MUDError module to be defined after requiring errors.rb')
end

When('I instantiate an Aethyr error {string} with message {string}') do |klass, msg|
  self.aethyr_error = MUDError.const_get(klass).new(msg)
end

Then('the Aethyr error should be a kind of RuntimeError') do
  assert_kind_of(RuntimeError, aethyr_error,
                 "Expected a RuntimeError descendant, got #{aethyr_error.class}")
end

Then('the Aethyr error message should be {string}') do |expected|
  assert_equal(expected, aethyr_error.message)
end

When('I raise an Aethyr error {string} with message {string}') do |klass, msg|
  self.aethyr_rescued_error = nil
  begin
    raise MUDError.const_get(klass), msg
  rescue MUDError.const_get(klass) => e
    self.aethyr_rescued_error = e
  end
end

Then('the Aethyr error should have been rescued') do
  assert_not_nil(aethyr_rescued_error,
                 'Expected an error to be rescued but none was caught')
end

Then('the Aethyr error class name should be {string}') do |expected|
  assert_equal(expected, aethyr_rescued_error.class.name)
end
