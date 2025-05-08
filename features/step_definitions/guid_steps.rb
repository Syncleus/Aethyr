# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step-definitions for GUID feature
#
# These steps illustrate SOLID & Design-Pattern principles even in test-code:
#
#   • Single-Responsibility — every helper object does **exactly one** thing.
#   • Open/Closed            — helpers can be extended without modification.
#   • Liskov Substitution    — polymorphic contracts honoured via duck-typing.
#   • Interface Segregation  — minimal, well-named public APIs.
#   • Dependency Inversion   — steps depend on the Guid interface, not its impl.
#
# Patterns employed:
#   • Facade        – GuidHelpers presents a tiny, intention-revealing surface
#                     over the underlying Guid mechanics.
#   • Builder       – GuidFactory cleanly constructs collections of GUID objects.
#   • Mixin         – Test assertions & helpers are composed à-la-carte.
# -----------------------------------------------------------------------------

require 'test/unit/assertions'
World(Test::Unit::Assertions)

# ----------------------------------------------------------------------------- 
# Facade: houses **all** logic for validating GUIDs, hiding regex internals.
# -----------------------------------------------------------------------------
module GuidHelpers
  # Canonical RFC-4122 compliant 36-character GUID pattern
  GUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i.freeze

  # Predicate: does +guid+ (object responding to #to_s) match the canonical form?
  #
  # Returns boolean; raises nothing – keeps the contract minimal and predictable.
  def valid_guid?(guid)
    !!(guid.to_s =~ GUID_REGEX)
  end
end
World(GuidHelpers)

# ----------------------------------------------------------------------------- 
# Builder: responsible for manufacturing an arbitrary number of GUIDs.
# -----------------------------------------------------------------------------
class GuidFactory
  # Dependency-Injection: the concrete +guid_class+ is supplied by caller,
  # making the factory open for extension (custom GUID implementations) while
  # closed for modification.
  def initialize(guid_class)
    @guid_class = guid_class
  end

  # @param count [Integer] number of GUID instances to build
  # @return [Array<#to_s, #raw>] freshly minted GUID objects
  def build_many(count)
    Array.new(count) { @guid_class.new }
  end
end

# -----------------------------------------------------------------------------
#                       C U C U M B E R   S T E P S
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