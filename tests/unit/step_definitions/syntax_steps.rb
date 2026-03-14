# frozen_string_literal: true

###############################################################################
# Step-definitions that verify Syntax.find lookups.                           #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

module SyntaxWorld
  attr_accessor :syntax_result
end
World(SyntaxWorld)

Given('I require the Syntax library') do
  require 'aethyr/core/help/syntax'
end

When('I look up the syntax for {string}') do |command|
  @syntax_result = Syntax.find(command)
end

Then('the syntax result should be {string}') do |expected|
  assert_equal(expected, @syntax_result,
               "Expected Syntax.find to return #{expected.inspect}, got #{@syntax_result.inspect}")
end

Then('the syntax result should be nil') do
  assert_nil(@syntax_result, "Expected nil but got #{@syntax_result.inspect}")
end
