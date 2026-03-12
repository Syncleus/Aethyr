# frozen_string_literal: true

###############################################################################
# Step-definitions for MCCP (MUD Client Compression Protocol) feature         #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module – holds per-scenario state for MCCP tests
# ---------------------------------------------------------------------------
module MCCPWorld
  attr_accessor :mccp_instance, :mccp_compressed, :mccp_decompressed, :mccp_step_result
end
World(MCCPWorld)

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------
Given('I require the MCCP library') do
  require 'aethyr/core/connection/mccp'
  assert defined?(MCCP), 'MCCP class should be defined after require'
end

When('I create a new MCCP instance') do
  self.mccp_instance = MCCP.new
end

Then('the MCCP instance step should be {string}') do |expected|
  actual = mccp_instance.instance_variable_get(:@step)
  assert_equal expected, actual,
               "Expected MCCP @step to be #{expected.inspect}, got #{actual.inspect}"
end

When('I call MCCP step with {string}') do |input|
  self.mccp_step_result = mccp_instance.step(input)
end

Then('the MCCP step call should return without error') do
  # The step method is a no-op stub; reaching this point means it did not raise.
  assert true, 'MCCP#step should not raise'
end

When('I compress the string {string} using MCCP') do |plaintext|
  self.mccp_compressed = MCCP.compress(plaintext)
end

Then('the MCCP compressed result should be a non-empty binary string') do
  assert_not_nil mccp_compressed, 'Compressed result should not be nil'
  assert mccp_compressed.length > 0, 'Compressed result should not be empty'
end

Then('the MCCP compressed result should differ from {string}') do |original|
  assert_not_equal original, mccp_compressed,
                   'Compressed output should not be identical to the original plaintext'
end

When('I decompress the MCCP compressed result') do
  self.mccp_decompressed = MCCP.decompress(mccp_compressed)
end

Then('the MCCP decompressed result should equal {string}') do |expected|
  assert_equal expected, mccp_decompressed,
               "Expected decompressed text to be #{expected.inspect}, got #{mccp_decompressed.inspect}"
end
