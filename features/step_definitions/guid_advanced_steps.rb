# frozen_string_literal: true
# -----------------------------------------------------------------------------
#  GUID – Advanced/edge-case step-definitions
# -----------------------------------------------------------------------------
#  Jeffrey Phillips Freeman (authorial-style commentary):
#
#  This file complements, rather than pollutes, the original GUID façade found
#  in `guid_steps.rb`.  Each step focuses on a *single* behaviour and depends
#  only upon the Guid public interface, thereby exemplifying:
#
#    • SRP   – one reason to change: the wording of a specific Cucumber step.
#    • ISP   – we expose only the micro-API the steps require.
#    • OCP   – new steps can be added via mix-ins; no edits to existing code.
#    • DIP   – the high-level tests depend on the *abstraction* of Guid, not on
#              its concrete byte-generation strategy.
#
#  Design patterns on display:
#
#    • Facade      – GuidAdvancedHelpers presents a tiny, intention-revealing
#                    surface for string normalisation.
#    • Null-Object – a miniature ServerConfig implementation stands in for the
#                    real configuration system when absent.
#    • Command     – each Cucumber step is an executable "specification unit".
# -----------------------------------------------------------------------------

require 'test/unit/assertions'
World(Test::Unit::Assertions)

# ----------------------------------------------------------------------------- 
# Helper Facade – keeps step logic readable & DRY
# -----------------------------------------------------------------------------
module GuidAdvancedHelpers
  # Normalises the potentially weird return types of Guid#to_s under different
  # ServerConfig modes (array vs. string).
  #
  # @param guid [Guid]
  # @return [String] canonical textual representation
  def canonical_guid_string(guid)
    representation = guid.to_s
    representation = representation.first if representation.is_a?(Array)
    representation.to_s
  end
end
World(GuidAdvancedHelpers)

# ----------------------------------------------------------------------------- 
# Hexdigest-related steps
# -----------------------------------------------------------------------------
Then('each GUID\'s hexdigest should be 32 hexadecimal characters') do
  @guids.each do |g|
    hex = g.hexdigest
    assert_equal(32, hex.length,
                 "Expected 32-char hexdigest but got #{hex.length} for #{hex.inspect}")
    assert_match(/\A[0-9a-f]{32}\z/i, hex,
                 "Hexdigest #{hex.inspect} contains non-hex characters")
  end
end

Then('each GUID\'s hexdigest should match its string representation without dashes') do
  @guids.each do |g|
    assert_equal(g.to_s.delete('-'), g.hexdigest,
                 'Removing dashes from #to_s should equal #hexdigest')
  end
end

# ----------------------------------------------------------------------------- 
# Error-handling steps
# -----------------------------------------------------------------------------
When('I attempt to parse the GUID string {string}') do |input|
  @exception = nil
  begin
    Guid.from_s(input)
  rescue => e
    @exception = e
  end
end

When('I attempt to parse raw GUID bytes of length {int}') do |len|
  @exception = nil
  begin
    Guid.from_raw('x' * len)
  rescue => e
    @exception = e
  end
end

Then('an ArgumentError should be raised with message {string}') do |expected|
  assert_not_nil(@exception, 'Expected an exception but none was raised')
  assert_instance_of(ArgumentError, @exception,
                     "Expected ArgumentError but got #{@exception.class}")
  assert_equal(expected, @exception.message)
end

# ----------------------------------------------------------------------------- 
# ServerConfig / GOID type steps
# -----------------------------------------------------------------------------
# A Null-Object stand-in for systems that have not yet defined ServerConfig.
unless defined?(ServerConfig)
  module ServerConfig
    @data = {}

    class << self
      # Retrieve a configuration entry.
      #
      # @param key [Object] lookup key
      # @return [Object] stored value or nil
      def [](key)
        @data[key]
      end

      # Assign a configuration entry.
      #
      # @param key   [Object] lookup key
      # @param value [Object] value to store
      # @return [Object] the value written
      def []=(key, value)
        @data[key] = value
      end

      # Clear **all** configuration (used by tests for teardown/reset).
      #
      # @return [void]
      def reset!
        @data.clear
      end
    end
  end
end

Given('I set the GOID type to {string}') do |type|
  @previous_goid_type = ServerConfig[:goid_type]
  ServerConfig[:goid_type] = type.to_sym
end

Then('the GOID strings should match the {string} pattern') do |type|
  @guids.each do |g|
    s = canonical_guid_string(g)

    case type
    when 'hex_code'
      assert_match(/\A[0-9a-f]{6}\z/i, s,
                   "hex_code expected 6-char hex, got #{s.inspect}")
    when 'integer_16'
      assert_match(/\A\d+\z/, s)
      assert((0..65_535).cover?(Integer(s)),
             "integer_16 out of range: #{s}")
    when 'integer_24'
      assert_match(/\A\d+\z/, s)
      assert((0..16_777_216).cover?(Integer(s)),
             "integer_24 out of range: #{s}")
    when 'integer_32'
      assert_match(/\A\d+\z/, s)
      assert((0..4_294_967_296).cover?(Integer(s)),
             "integer_32 out of range: #{s}")
    else
      flunk("Unknown GOID type #{type.inspect}")
    end
  end
end

Then('I reset the GOID type') do
  ServerConfig[:goid_type] = @previous_goid_type
end 