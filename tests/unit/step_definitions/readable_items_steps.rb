# frozen_string_literal: true

###############################################################################
# Step-definitions for Scroll / Readable-items feature.                       #
#                                                                             #
# All step text is prefixed with "Scroll" to avoid collisions with other      #
# step-definition files in the suite.                                         #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module – holds per-scenario state for Scroll tests.
# ---------------------------------------------------------------------------
module ScrollWorld
  attr_accessor :scroll
end
World(ScrollWorld)

# ---------------------------------------------------------------------------
# Lightweight $manager stub so that GameObject#initialize can call
# `$manager.existing_goid?` without the full game engine running.
# Guarded so it does not clash with other files that define StubManager.
# ---------------------------------------------------------------------------
unless defined?(ScrollStubManager)
  class ScrollStubManager
    def existing_goid?(_goid)
      false
    end

    def submit_action(action)
      # no-op
    end
  end
end

# ---------------------------------------------------------------------------
# Given
# ---------------------------------------------------------------------------
Given('I require the Scroll library') do
  $manager ||= ScrollStubManager.new
  # The require itself exercises lines 1-2 (requires) and 4-6/11-12
  # (module + class declarations, include Readable).
  require 'aethyr/core/objects/scroll'
end

# ---------------------------------------------------------------------------
# When
# ---------------------------------------------------------------------------
When('a Scroll object is created') do
  $manager = ScrollStubManager.new unless $manager.respond_to?(:existing_goid?)
  # Instantiation exercises lines 14-23 (initialize body) and closes
  # lines 24-27 (end statements).
  self.scroll = Aethyr::Core::Objects::Scroll.new
end

When('the Scroll readable_text is set to {string}') do |text|
  scroll.readable_text = text
end

# ---------------------------------------------------------------------------
# Then
# ---------------------------------------------------------------------------
Then('the Scroll generic should be {string}') do |expected|
  assert_equal expected, scroll.generic
end

Then('the Scroll should be movable') do
  assert scroll.can_move?, 'Expected scroll to be movable'
end

Then('the Scroll short_desc should be {string}') do |expected|
  assert_equal expected, scroll.short_desc
end

Then('the Scroll long_desc should be {string}') do |expected|
  assert_equal expected, scroll.long_desc
end

Then('the Scroll alt_names should include {string}') do |name|
  assert_includes scroll.alt_names, name
end

Then('the Scroll info writable should be true') do
  assert scroll.info.writable, 'Expected info.writable to be true'
end

Then('the Scroll should respond to readable_text') do
  assert scroll.respond_to?(:readable_text),
         'Expected Scroll to respond to :readable_text (from Readable)'
end

Then('the Scroll actions should include {string}') do |action|
  assert scroll.actions.include?(action),
         "Expected actions to include #{action.inspect}"
end

Then('the Scroll readable_text should be nil by default') do
  assert_nil scroll.readable_text
end

Then('the Scroll should be a kind of GameObject') do
  assert_kind_of Aethyr::Core::Objects::GameObject, scroll
end

Then('the Scroll readable_text should equal {string}') do |expected|
  assert_equal expected, scroll.readable_text
end

# ---------------------------------------------------------------------------
# Mock player for exercising the Readable#read method
# ---------------------------------------------------------------------------
unless defined?(ReadableMockPlayer)
  class ReadableMockPlayer
    attr_reader :messages
    attr_writer :is_blind

    def initialize(blind: false)
      @is_blind = blind
      @messages = []
    end

    def blind?
      @is_blind
    end

    def output(message, *_args)
      @messages << message
    end
  end
end

# ---------------------------------------------------------------------------
# When – reading with mock players
# ---------------------------------------------------------------------------
When('a blind mock player reads the Scroll') do
  @mock_player = ReadableMockPlayer.new(blind: true)
  @read_result = scroll.read(nil, @mock_player, nil)
end

When('a sighted mock player reads the Scroll') do
  @mock_player = ReadableMockPlayer.new(blind: false)
  @read_result = scroll.read(nil, @mock_player, nil)
end

# ---------------------------------------------------------------------------
# Then – assertions on read results and player output
# ---------------------------------------------------------------------------
Then('the blind read should return false') do
  assert_equal false, @read_result
end

Then('the mock player output should include {string}') do |expected|
  combined = @mock_player.messages.join("\n")
  assert_includes combined, expected
end
