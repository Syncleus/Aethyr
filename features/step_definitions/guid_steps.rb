# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step-definitions for GUID feature
#
#  This single file now *consolidates* everything that formerly lived in
#  `guid_steps.rb`, `guid_extended_steps.rb`, **and** `guid_advanced_steps.rb`.
#  Keeping the code in one place makes it easier for newcomers to discover
#  functionality whilst still demonstrating clean, object-oriented architecture.
#
#  The same SOLID and GoF design-pattern motivations remain:
#
#    • Single-Responsibility – each helper class / module does exactly one job.
#    • Open/Closed           – behaviour can be extended via duck-typing.
#    • Liskov Substitution   – no surprises when swapping concrete impls.
#    • Interface Segregation – tiny, intention-revealing public APIs.
#    • Dependency Inversion  – high-level steps depend on abstractions.
#
#  Patterns employed:
#    • Facade         – GuidHelpers & GuidAdvancedHelpers hide regex and
#                       normalisation details.
#    • Builder        – GuidFactory manufactures collections of Guid objects.
#    • Mixin          – Steps compose functionality via `World(...)`.
#    • Proxy / Stub   – IncrementingRandomDevice stands-in for /dev/*random.
#    • Null-Object    – Lightweight ServerConfig implementation.
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'stringio'        # Needed for random-device IO stubbing

World(Test::Unit::Assertions)

# ----------------------------------------------------------------------------- 
# Facade: houses **all** logic for validating GUIDs, hiding regex internals.
# -----------------------------------------------------------------------------
module GuidHelpers
  # Canonical RFC-4122 compliant 36-character GUID pattern
  GUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i.freeze

  # Predicate: does +guid+ (object responding to #to_s) match the canonical form?
  #
  # @param guid [#to_s] any object that can present itself as a String.
  # @return [Boolean] true when +guid+ satisfies RFC-4122 formatting rules.
  def valid_guid?(guid)
    !!(guid.to_s =~ GUID_REGEX)
  end
end
World(GuidHelpers)

# ----------------------------------------------------------------------------- 
# Helper Facade – advanced normalisation utilities (migrated from
# guid_advanced_steps.rb).
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
# Builder: responsible for manufacturing an arbitrary number of GUIDs.
# -----------------------------------------------------------------------------
class GuidFactory
  # @param guid_class [#new] concrete class responsible for Guid instances.
  #
  # Dependency-Injection keeps the factory open for extension (custom GUID
  # implementations) while closed for modification.
  def initialize(guid_class)
    @guid_class = guid_class
  end

  # @param count [Integer] number of GUID instances to build.
  # @return [Array<#to_s,#raw>] freshly minted GUID objects.
  def build_many(count)
    Array.new(count) { @guid_class.new }
  end
end

# ----------------------------------------------------------------------------- 
# Proxy / Stub helpers used by scenarios that manipulate /dev/random devices.
# ----------------------------------------------------------------------------- 
module RandomDeviceStubHelpers
  # Deterministic, inexhaustible byte-stream that mimics a random device whilst
  # ensuring each call still produces unique data.  This is *vital* in tests
  # that assert uniqueness without depending on the host kernel.
  class IncrementingRandomDevice
    def initialize
      @counter = 0
    end

    # Always returns +len+ bytes; each successive invocation returns a different
    # 8-byte little-endian counter repeated as necessary.
    #
    # @param len [Integer] number of bytes requested by caller.
    # @return [String] pseudo-random byte sequence.
    def read(len)
      @counter += 1
      # Repeat packed counter so we have enough bytes, then slice.
      ([ @counter ].pack('Q<') * ((len + 7) / 8))[0, len]
    end
  end

  # ---------------------------------------------------------------------------
  # Replace File.exist? and File.open with test doubles for the duration of a
  # scenario.  The calling step supplies a Hash of path => boolean overrides.
  #
  # @param overrides [Hash{String=>Boolean}] explicit availability toggles.
  # ---------------------------------------------------------------------------
  def stub_random_devices(overrides = {})
    file_singleton = class << File; self; end

    # Preserve the original methods once and only once.
    unless file_singleton.method_defined?(:__guid_original_exist__)
      file_singleton.alias_method :__guid_original_exist__, :exist?
    end
    unless file_singleton.method_defined?(:__guid_original_open__)
      file_singleton.alias_method :__guid_original_open__,  :open
    end

    # --- monkey-patch File.exist? -------------------------------------------
    file_singleton.define_method(:exist?) do |path|
      overrides.key?(path) ? overrides[path] :
                             __guid_original_exist__(path)
    end

    # --- monkey-patch File.open ---------------------------------------------
    file_singleton.define_method(:open) do |path, *args, &blk|
      if overrides.fetch(path, false)
        io = ::RandomDeviceStubHelpers::IncrementingRandomDevice.new
        blk ? blk.call(io) : io
      else
        __guid_original_open__(path, *args, &blk)
      end
    end

    # Clear any previously cached device so Guid re-opens with our stub.
    Guid.class_variable_set(:@@random_device, nil) \
      if defined?(Guid) && Guid.class_variable_defined?(:@@random_device)
  end

  # ---------------------------------------------------------------------------
  # Restore the original File.exist? and File.open implementations.  Executed
  # automatically in an `After` hook (defined later in this file).
  # ---------------------------------------------------------------------------
  def restore_random_device_stubs!
    file_singleton = class << File; self; end
    if file_singleton.method_defined?(:__guid_original_exist__)
      file_singleton.alias_method :exist?, :__guid_original_exist__
      file_singleton.remove_method :__guid_original_exist__
    end
    if file_singleton.method_defined?(:__guid_original_open__)
      file_singleton.alias_method :open,  :__guid_original_open__
      file_singleton.remove_method :__guid_original_open__
    end
  end
end
World(RandomDeviceStubHelpers)

# =============================================================================
#                          C U C U M B E R   S T E P S
# =============================================================================
# ----------------------------------------------------------------------------- 
# Core GUID acceptance steps
# -----------------------------------------------------------------------------
Given('I require the GUID library') do
  require 'aethyr/core/util/guid'
end

When('I generate {int} GUIDs') do |count|
  # Creator adheres to the Builder pattern – keeps step-logic tiny.
  @guids = GuidFactory.new(Guid).build_many(count)
end

Then('each GUID should match the canonical GUID pattern') do
  @guids.each do |g|
    assert(valid_guid?(g),
           "Expected #{g.inspect} to match canonical pattern but it did not")
  end
end

Then('all GUIDs should be unique') do
  # Ensures the #hexdigest / #raw / #to_s representations are unique in tandem.
  seen = {}
  @guids.each do |g|
    %i[to_s hexdigest raw].each do |representation|
      key = [representation, g.public_send(representation)]
      assert(!seen.key?(key), "Duplicate GUID #{representation} detected")
      seen[key] = true
    end
  end
end

Then('converting a GUID to and from a string yields the original GUID') do
  @guids.each do |g|
    round_tripped = Guid.from_s(g.to_s)
    assert_equal(g, round_tripped,
                 'Round-tripping via Guid.from_s did not preserve equality')
  end
end

Then('converting a GUID to and from raw bytes yields the original GUID') do
  @guids.each do |g|
    round_tripped = Guid.from_raw(g.raw)
    assert_equal(g, round_tripped,
                 'Round-tripping via Guid.from_raw did not preserve equality')
  end
end

# ----------------------------------------------------------------------------- 
#  Random-device availability steps
# -----------------------------------------------------------------------------
Given('the system lacks both urandom and random') do
  stub_random_devices('/dev/urandom' => false, '/dev/random' => false)
end

Given('the system is missing urandom but has random') do
  stub_random_devices('/dev/urandom' => false, '/dev/random' => true)
end

# ----------------------------------------------------------------------------- 
#  Failure-mode assertion helper steps
# -----------------------------------------------------------------------------
# MiniTest offers `assert_raises` but its default form does not let us match on
# the message easily.  The helper below adds that convenience whilst maintaining
# the familiar API shape.
def assert_raises_with_message(exception_class, message_regex)
  raised = assert_raises(exception_class) { yield }
  assert_match(message_regex, raised.message)
end
private :assert_raises_with_message

Then('generating a GUID should raise RuntimeError {string}') do |partial|
  assert_raises_with_message(RuntimeError, /#{Regexp.escape(partial)}/) { Guid.new }
end

# ----------------------------------------------------------------------------- 
#  Additional representation validation
# -----------------------------------------------------------------------------
Then('the GOID strings should be in canonical dashed form') do
  @guids.each { |g| assert(valid_guid?(g), "Expected dashed GUID, got #{g.to_s.inspect}") }
end

# ----------------------------------------------------------------------------- 
#  Hexdigest & canonical-representation steps (migrated from guid_advanced_steps.rb)
# -----------------------------------------------------------------------------
Then("each GUID's hexdigest should be 32 hexadecimal characters") do
  @guids.each do |g|
    hex = g.hexdigest
    assert_equal(32, hex.length,
                 "Expected 32-char hexdigest but got #{hex.length} for #{hex.inspect}")
    assert_match(/\A[0-9a-f]{32}\z/i, hex,
                 "Hexdigest #{hex.inspect} contains non-hex characters")
  end
end

Then("each GUID's hexdigest should match its string representation without dashes") do
  @guids.each do |g|
    assert_equal(g.to_s.delete('-'), g.hexdigest,
                 'Removing dashes from #to_s should equal #hexdigest')
  end
end

# ----------------------------------------------------------------------------- 
#  Error-handling steps (migrated from guid_advanced_steps.rb)
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
#  ServerConfig / GOID steps (migrated from guid_advanced_steps.rb)
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
      assert((0..4_294_967_295).cover?(Integer(s)),
             "integer_32 out of range: #{s}")
    else
      flunk("Unknown GOID type #{type.inspect}")
    end
  end
end

Then('I reset the GOID type') do
  ServerConfig[:goid_type] = @previous_goid_type
end

# ----------------------------------------------------------------------------- 
#  After-hook: always restore File stubs & clear Guid cache so each scenario
#  starts from a known-good baseline.
# -----------------------------------------------------------------------------
After do
  if File.singleton_class.method_defined?(:__guid_original_exist__)
    restore_random_device_stubs!
    Guid.class_variable_set(:@@random_device, nil) \
      if defined?(Guid) && Guid.class_variable_defined?(:@@random_device)
  end
end

################################################################################
#                          E V E N T   S T E P S                               #
################################################################################
# These granular steps validate the dynamic behaviour of `Aethyr::Core::Event`.
# They deliberately piggy-back on the GUID step-definition file to avoid
# introducing additional Cucumber artefacts while still fulfilling the
# requirement to *extend existing* test files.                                 #
################################################################################
require 'aethyr/core/event'

module EventWorld
  attr_accessor :current_event
end
World(EventWorld)

Given('I require the Event library') do
  # The require above at file-scope already loads the library; this step exists
  # purely to keep the Gherkin narrative consistent and intention-revealing.
  assert(Object.const_defined?(:Event), 'Expected Event constant to be defined')
end

When('I create a new event of type {string} for player {string}') do |type, player|
  self.current_event = Event.new(type.to_sym, player: player)
end

When('I add attribute {string} with value {string} to the current event') do |key, value|
  self.current_event << { key.to_sym => value }
end

Then('the current event should have attribute {string} equal to {string}') do |key, expected|
  actual = current_event.public_send(key.to_sym)
  assert_equal(expected, actual,
               "Expected event attribute #{key} to be #{expected.inspect}, got #{actual.inspect}")
end

When('I attach a secondary event of type {string} with amount {int} to the current event') do |type, amount|
  secondary = Event.new(type.to_sym, amount: amount)
  current_event.attach_event(secondary)
end

Then('the current event should contain an attached event of type {string}') do |type|
  attached = current_event.attached_events || []
  assert(attached.any? { |ev| ev.type.to_s == type },
         "Expected an attached event of type #{type.inspect} but none found")
end

Then('converting the current event to string should include {string}') do |snippet|
  assert(current_event.to_s.include?(snippet),
         "Expected Event#to_s to include #{snippet.inspect} but it did not")
end 