# frozen_string_literal: true
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# Helper module – holds the loaded constant values for telnet codes scenarios
# ---------------------------------------------------------------------------
module TelnetCodesHelpers
  # Looks up a top-level constant by name that was defined in telnet_codes.rb
  #
  # @param name [String] constant name (e.g. "IAC", "OPT_ECHO")
  # @return [String] the single-byte string value
  def telnet_const(name)
    Object.const_get(name)
  end

  # Interprets octal escape sequences (e.g. \000, \015, \012) in a literal
  # string captured by Cucumber's {string} parameter type.
  def unescape_octal(str)
    str.gsub(/\\([0-7]{1,3})/) { $1.to_i(8).chr }
  end
end
World(TelnetCodesHelpers)

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

Given('I require the telnet codes library') do
  require 'aethyr/core/connection/telnet_codes'
end

# Matches: the telnet codes IAC constant should equal byte 255
Then('the telnet codes {word} constant should equal byte {int}') do |name, value|
  assert_equal(value.chr, telnet_const(name),
               "Expected #{name} to equal #{value}.chr but got #{telnet_const(name).inspect}")
end

# Matches: the Telnet protocol constant OPT_ECHO should equal byte 1
Then('the Telnet protocol constant {word} should equal byte {int}') do |name, value|
  assert_equal(value.chr, telnet_const(name),
               "Expected #{name} to equal #{value}.chr but got #{telnet_const(name).inspect}")
end

# Matches: the telnet codes NULL constant should equal "\000"
Then('the telnet codes NULL constant should equal {string}') do |expected|
  expected = unescape_octal(expected)
  actual = telnet_const('NULL')
  assert_equal(expected, actual,
               "Expected NULL to equal #{expected.inspect} but got #{actual.inspect}")
end

Then('the telnet codes CR constant should equal {string}') do |expected|
  expected = unescape_octal(expected)
  actual = telnet_const('CR')
  assert_equal(expected, actual,
               "Expected CR to equal #{expected.inspect} but got #{actual.inspect}")
end

Then('the telnet codes LF constant should equal {string}') do |expected|
  expected = unescape_octal(expected)
  actual = telnet_const('LF')
  assert_equal(expected, actual,
               "Expected LF to equal #{expected.inspect} but got #{actual.inspect}")
end

Then('the telnet codes EOL constant should equal CR followed by LF') do
  cr  = telnet_const('CR')
  lf  = telnet_const('LF')
  eol = telnet_const('EOL')
  assert_equal(cr + lf, eol,
               "Expected EOL to equal CR + LF but got #{eol.inspect}")
end
