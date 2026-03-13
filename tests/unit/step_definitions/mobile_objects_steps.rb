# frozen_string_literal: true

###############################################################################
# Step definitions for Mobile object scenarios                                 #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module to hold scenario state
# ---------------------------------------------------------------------------
module MobileObjectWorld
  attr_accessor :mobile_instance, :redirect_target_output

  # Lightweight output-capturing object used as a redirect target
  class OutputCapture
    attr_reader :messages

    def initialize
      @messages = []
    end

    def output(msg, *_args)
      @messages << msg
    end

    def name
      'OutputCapture'
    end
  end

  # Stub manager for Mobile tests
  class MobileStubManager
    attr_accessor :objects

    def initialize
      @objects = {}
    end

    def existing_goid?(_goid)
      false
    end

    def submit_action(_action)
      # no-op
    end

    def get_object(goid)
      @objects[goid]
    end
  end
end
World(MobileObjectWorld)

# ---------------------------------------------------------------------------
# Ensure ServerConfig and logging exist
# ---------------------------------------------------------------------------
unless defined?(ServerConfig)
  module ServerConfig
    @data = {}
    class << self
      def [](key);       @data[key]; end
      def []=(key, val); @data[key] = val; end
      def reset!;        @data.clear; end
    end
  end
end

# ---------------------------------------------------------------------------
# Background step
# ---------------------------------------------------------------------------
Given('the Mobile library is loaded') do
  ServerConfig[:log_level] ||= 0

  unless defined?($LOG) && $LOG
    require 'aethyr/core/util/log'
    $LOG = Logger.new('logs/test_mobile.log')
  end

  $manager = MobileObjectWorld::MobileStubManager.new

  # Define the Generic constant that mobile.rb uses as a bare constant
  # (other files use :Generic symbol, but mobile.rb uses Generic)
  Object.const_set(:Generic, :Generic) unless defined?(Generic)

  require 'aethyr/core/objects/mobile'
end

# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------
Given('a Mobile object is created') do
  $manager = MobileObjectWorld::MobileStubManager.new
  self.mobile_instance = Aethyr::Core::Objects::Mobile.new
  self.redirect_target_output = nil
end

# ---------------------------------------------------------------------------
# short_desc
# ---------------------------------------------------------------------------
Then('the Mobile short_desc should be {string}') do |expected|
  assert_equal expected, mobile_instance.short_desc
end

# ---------------------------------------------------------------------------
# balance=
# ---------------------------------------------------------------------------
When('the Mobile balance is set to false') do
  mobile_instance.balance = false
end

When('the Mobile balance is set to true') do
  mobile_instance.balance = true
end

Then('the Mobile balance should be false') do
  assert_equal false, mobile_instance.balance
end

Then('the Mobile balance should be true') do
  assert_equal true, mobile_instance.balance
end

# ---------------------------------------------------------------------------
# blind? / deaf?
# ---------------------------------------------------------------------------
Then('the Mobile blind? should be false') do
  assert_equal false, mobile_instance.blind?
end

Then('the Mobile deaf? should be false') do
  assert_equal false, mobile_instance.deaf?
end

# ---------------------------------------------------------------------------
# out_event - with redirect_output_to
# ---------------------------------------------------------------------------
Given('the Mobile has redirect_output_to enabled') do
  capture = MobileObjectWorld::OutputCapture.new
  capture_goid = 'redirect-target-goid'
  $manager.objects[capture_goid] = capture
  mobile_instance.info.redirect_output_to = capture_goid
  self.redirect_target_output = capture
end

When('the Mobile receives an out_event where target is self') do
  other = Object.new
  event = Event.new(:Generic,
    action: :say,
    target: mobile_instance,
    player: other,
    to_target: 'target-msg',
    to_player: 'player-msg',
    to_other: 'other-msg'
  )
  mobile_instance.out_event(event)
end

When('the Mobile receives an out_event where player is self') do
  other = Object.new
  event = Event.new(:Generic,
    action: :say,
    target: other,
    player: mobile_instance,
    to_target: 'target-msg',
    to_player: 'player-msg',
    to_other: 'other-msg'
  )
  mobile_instance.out_event(event)
end

When('the Mobile receives an out_event where neither target nor player is self') do
  other1 = Object.new
  other2 = Object.new
  event = Event.new(:Generic,
    action: :say,
    target: other1,
    player: other2,
    to_target: 'target-msg',
    to_player: 'player-msg',
    to_other: 'other-msg'
  )
  mobile_instance.out_event(event)
end

Then('the Mobile redirected output should include {string}') do |expected|
  messages = redirect_target_output.messages
  found = messages.any? { |m| m.to_s.include?(expected) }
  assert found, "Expected redirected output to include '#{expected}', got: #{messages.inspect}"
end

# ---------------------------------------------------------------------------
# output with redirect
# ---------------------------------------------------------------------------
When('the Mobile output is called with {string}') do |message|
  mobile_instance.output(message)
end

Then('the Mobile redirect target should have received {string}') do |expected|
  assert_not_nil redirect_target_output, "No redirect target configured"
  messages = redirect_target_output.messages
  found = messages.any? { |m| m.to_s.include?(expected) }
  assert found, "Expected redirect target to have received '#{expected}', got: #{messages.inspect}"
end

Then('the Mobile redirect target should have received nothing') do
  if redirect_target_output
    assert redirect_target_output.messages.empty?,
           "Expected no output, got: #{redirect_target_output.messages.inspect}"
  end
  # If redirect_target_output is nil, there's nothing to check
end

# ---------------------------------------------------------------------------
# output with missing redirect target
# ---------------------------------------------------------------------------
Given('the Mobile has redirect_output_to a missing object') do
  mobile_instance.info.redirect_output_to = 'nonexistent-goid'
  # $manager.get_object will return nil for this goid
  self.redirect_target_output = MobileObjectWorld::OutputCapture.new
end

# ---------------------------------------------------------------------------
# long_desc
# ---------------------------------------------------------------------------
Then('the Mobile long_desc should include {string}') do |expected|
  desc = mobile_instance.long_desc
  assert desc.include?(expected),
         "Expected long_desc to include '#{expected}', got: #{desc.inspect}"
end

# ---------------------------------------------------------------------------
# take_damage
# ---------------------------------------------------------------------------
When('the Mobile takes {int} damage') do |amount|
  mobile_instance.take_damage(amount)
end

When('the Mobile takes {int} health damage') do |amount|
  mobile_instance.take_damage(amount, :health)
end

Then('the Mobile health should be {int}') do |expected|
  assert_equal expected, mobile_instance.info.stats.health
end
