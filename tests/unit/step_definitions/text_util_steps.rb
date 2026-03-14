# frozen_string_literal: true
################################################################################
# Step-definitions validating TextUtil#wrap                                     #
#                                                                              #
# A lightweight wrapper class includes the TextUtil module so that the         #
# private helper #shift and the public #wrap method can be exercised in        #
# isolation without coupling to any production rendering pipeline.             #
################################################################################

require 'test/unit/assertions'
require 'aethyr/core/render/text_util'

World(Test::Unit::Assertions)

###############################################################################
# Test harness – thin class that mixes in TextUtil                             #
###############################################################################
class TextUtilWrapper
  include TextUtil
  # Make the private shift method accessible for wrap's internal use.
  public :shift
end

###############################################################################
# Shared state                                                                 #
###############################################################################
module TextUtilWorld
  attr_accessor :tu_wrapper, :tu_result
end
World(TextUtilWorld)

###############################################################################
# Given                                                                        #
###############################################################################
Given('a TextUtil wrapper instance') do
  @tu_wrapper = TextUtilWrapper.new
end

###############################################################################
# When                                                                         #
###############################################################################

When('I wrap the text_util message {string} at width {int}') do |message, width|
  @tu_result = @tu_wrapper.wrap(message, width)
end

When('I wrap a text_util message with ANSI codes and width {int}') do |width|
  # \e[31m = red, \e[0m = reset  – neither should count toward width
  @tu_result = @tu_wrapper.wrap("\e[31mHello dad\e[0m", width)
end

When('I wrap the text_util message with CRLF newlines at width {int}') do |width|
  @tu_result = @tu_wrapper.wrap("hello\r\nworld", width)
end

When('I wrap the text_util message with NLCR newlines at width {int}') do |width|
  @tu_result = @tu_wrapper.wrap("hello\n\rworld", width)
end

When('I wrap the text_util message with a lone CR at width {int}') do |width|
  @tu_result = @tu_wrapper.wrap("hello\rworld", width)
end

When('I wrap the text_util message with a lone LF at width {int}') do |width|
  @tu_result = @tu_wrapper.wrap("hello\nworld", width)
end

When('I wrap a text_util message with a {int}-char word at width {int}') do |len, width|
  word = ('a'..'z').to_a[0, len].join
  @tu_result = @tu_wrapper.wrap(word, width)
end

###############################################################################
# Then                                                                         #
###############################################################################

Then('the text_util result should have {int} line(s)') do |count|
  assert_equal(count, @tu_result.length,
               "Expected #{count} line(s) but got #{@tu_result.length}: #{@tu_result.inspect}")
end

Then('text_util line {int} should be {string}') do |index, expected|
  assert_equal(expected, @tu_result[index],
               "Expected line #{index} to be #{expected.inspect} but got #{@tu_result[index].inspect}")
end

Then('the text_util result should contain the ANSI escape sequence') do
  joined = @tu_result.join
  assert(joined.include?("\e[31m"),
         "Expected ANSI escape \\e[31m in result but got: #{joined.inspect}")
  assert(joined.include?("\e[0m"),
         "Expected ANSI reset \\e[0m in result but got: #{joined.inspect}")
end

Then('the ANSI text_util wrap should not split mid-escape') do
  # The entire coloured text "Hello dad" (9 visible chars) fits in width 10,
  # so we expect a single line with both escape codes intact.
  assert_equal(1, @tu_result.length,
               "Expected 1 line for ANSI-wrapped text but got #{@tu_result.length}: #{@tu_result.inspect}")
  assert_equal("\e[31mHello dad\e[0m", @tu_result[0],
               "Expected full ANSI string in one line but got: #{@tu_result[0].inspect}")
end
