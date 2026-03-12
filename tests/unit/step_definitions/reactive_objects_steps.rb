# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step definitions for Reactor (reactive_objects.feature)
#
# Exercises every code path in lib/aethyr/core/objects/reactor.rb including:
#   - initialization, add, add_all
#   - react_to (matching/non-matching, passing/failing tests, errors)
#   - list_reactions, clear, to_s
#   - load from .rx file (comments, blanks, single/multi action)
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'set'
require 'fileutils'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# Helpers – lightweight stubs scoped to Reactor tests
# ---------------------------------------------------------------------------
module ReactorWorld
  attr_accessor :reactor, :reactor_mob, :reactor_commands, :reactor_rx_file

  # A minimal mob that supports .room, .name, and instance_eval (all objects do).
  class ReactorMob
    attr_accessor :room
    def initialize
      @room = 'test-room-id'
    end

    def name
      'TestMob'
    end
  end

  # Minimal $manager stand-in for Reactor tests.
  # Provides get_object (returns a stub room) required by react_to line 150.
  class ReactorStubManager
    def get_object(_goid)
      Object.new  # a simple stand-in for the room
    end

    def existing_goid?(_goid)
      false
    end
  end
end
World(ReactorWorld)

# ---------------------------------------------------------------------------
# Ensure ServerConfig and $LOG exist so `log` calls inside Reactor don't blow up
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
# Hooks
# ---------------------------------------------------------------------------
Before('@reactor') do
  # intentionally blank – tag-scoped setup if ever needed
end

After do
  # Clean up any temp .rx files created during the scenario
  if defined?(@reactor_rx_file) && @reactor_rx_file && File.exist?(@reactor_rx_file)
    FileUtils.rm_f(@reactor_rx_file)
  end
end

# ===========================================================================
#                              S T E P S
# ===========================================================================

# ── Background ────────────────────────────────────────────────────────────
Given('the Reactor library is loaded') do
  # Guarantee the logging infrastructure is present
  ServerConfig[:log_level] ||= 0

  # Provide a Logger so the `log` helper doesn't explode
  unless defined?($LOG) && $LOG
    require 'aethyr/core/util/log'
    $LOG = Logger.new('logs/test_reactor.log')
  end

  require 'aethyr/core/objects/reactor'
end

# ── Initialization ────────────────────────────────────────────────────────
Given('a Reactor object is created with a mock mob') do
  # Install a stub $manager that provides get_object
  $manager = ReactorWorld::ReactorStubManager.new

  self.reactor_mob = ReactorWorld::ReactorMob.new
  self.reactor     = Reactor.new(reactor_mob)
end

# ── to_s assertion ────────────────────────────────────────────────────────
Then('the Reactor to_s should report {int} reactions') do |count|
  assert_match(/#{count} reaction/, reactor.to_s,
               "Expected to_s to report #{count} reactions, got: #{reactor.to_s}")
end

Then('the Reactor to_s should report at least {int} reactions') do |min|
  m = reactor.to_s.match(/(\d+) reaction/)
  assert_not_nil(m, "to_s did not contain a reaction count: #{reactor.to_s}")
  actual = m[1].to_i
  assert(actual >= min,
         "Expected at least #{min} reactions, got #{actual}")
end

# ── Adding reactions ──────────────────────────────────────────────────────
When('a Reactor reaction with action {string} test {string} and reaction {string} is added') do |action, test_src, reaction_src|
  reaction_hash = {
    action:   action.to_sym,
    test:     test_src,
    reaction: reaction_src
  }
  reactor.add(reaction_hash)
end

When('a Reactor reaction with actions {string} test {string} and reaction {string} is added') do |actions_csv, test_src, reaction_src|
  action_list = actions_csv.split(',').map { |a| a.strip.to_sym }
  reaction_hash = {
    action:   action_list,
    test:     test_src,
    reaction: reaction_src
  }
  reactor.add(reaction_hash)
end

When('a Reactor reaction missing the test field is added') do
  reactor.add({ action: :say, test: nil, reaction: '"hello"' })
end

When('a Reactor reaction missing the action field is added') do
  reactor.add({ action: nil, test: 'true', reaction: '"hello"' })
end

When('a Reactor reaction missing the reaction field is added') do
  reactor.add({ action: :say, test: 'true', reaction: nil })
end

# ── add_all ───────────────────────────────────────────────────────────────
When('a Reactor batch of {int} valid reactions is added') do |count|
  reactions = count.times.map do |i|
    { action: :"act#{i}", test: 'true', reaction: "\"cmd#{i}\"" }
  end
  reactor.add_all(reactions)
end

# ── react_to ──────────────────────────────────────────────────────────────
When('the Reactor reacts to an event with action {string}') do |action|
  event = { action: action.to_sym }
  self.reactor_commands = reactor.react_to(event)
end

When('the Reactor reacts to an event with action {string} and a custom player') do |action|
  custom_player = Object.new
  def custom_player.name; 'CustomPlayer'; end

  event = { action: action.to_sym, player: custom_player }
  self.reactor_commands = reactor.react_to(event)
end

Then('the Reactor commands should include {string}') do |expected|
  assert(reactor_commands.is_a?(Array),
         "Expected commands to be an Array, got #{reactor_commands.class}")
  assert(reactor_commands.include?(expected),
         "Expected commands to include #{expected.inspect}, got #{reactor_commands.inspect}")
end

Then('the Reactor commands should be empty') do
  assert(reactor_commands.is_a?(Array),
         "Expected commands to be an Array, got #{reactor_commands.class}")
  assert(reactor_commands.empty?,
         "Expected empty commands, got #{reactor_commands.inspect}")
end

Then('the Reactor react_to result should be nil') do
  assert_nil(reactor_commands,
             "Expected react_to to return nil, got #{reactor_commands.inspect}")
end

# ── Broken test proc (triggers outer rescue in react_to) ──────────────────
When('a Reactor reaction with a broken test proc is added') do
  # We add a reaction whose RProc test will raise when called.
  # We need to bypass the normal add path and inject directly so the
  # RProc is already in place.  But actually, using a source that raises
  # will work because instance_eval("raise 'broken test'") raises.
  #
  # HOWEVER, the outer rescue on line 176 catches exceptions that escape
  # the matching loop (lines 152-159).  A raise in the test at line 154
  # will bubble up past the inner block to line 176.
  reaction_hash = {
    action:   :say,
    test:     "raise 'broken test'",
    reaction: '"never reached"'
  }
  reactor.add(reaction_hash)
end

# ── list_reactions ────────────────────────────────────────────────────────
Then('the Reactor list_reactions should mention action {string}') do |action|
  listing = reactor.list_reactions
  assert(listing.include?(action),
         "Expected list_reactions to mention '#{action}', got:\n#{listing}")
end

Then('the Reactor list_reactions should include the test source') do
  listing = reactor.list_reactions
  assert(listing.include?('Test:'),
         "Expected list_reactions to include 'Test:', got:\n#{listing}")
end

Then('the Reactor list_reactions should include the reaction source') do
  listing = reactor.list_reactions
  assert(listing.include?('Reaction:'),
         "Expected list_reactions to include 'Reaction:', got:\n#{listing}")
end

Then('the Reactor list_reactions should be blank') do
  listing = reactor.list_reactions
  assert(listing.empty? || listing.strip.empty?,
         "Expected blank list_reactions, got:\n#{listing}")
end

# ── clear ─────────────────────────────────────────────────────────────────
When('the Reactor reactions are cleared') do
  reactor.clear
end

# ── load from .rx file ────────────────────────────────────────────────────
Given('a Reactor test rx file exists with single and multi-action reactions') do
  dir = 'lib/aethyr/extensions/reactions'
  FileUtils.mkdir_p(dir)

  self.reactor_rx_file = File.join(dir, 'test_reactor_bdd.rx')

  content = <<~RX
    #This is a comment
    !action
    greet
    !test
    true
    !reaction
    "say hi"

    !action
    hug kiss
    !test
    true
    !reaction
    "wave"
  RX

  File.write(reactor_rx_file, content)
end

Given('a Reactor test rx file exists with comments and blanks') do
  dir = 'lib/aethyr/extensions/reactions'
  FileUtils.mkdir_p(dir)

  self.reactor_rx_file = File.join(dir, 'test_reactor_bdd.rx')

  content = <<~RX
    # Full-line comment at the top

    #Another comment
    !action
    wave
    !test
    true
    !reaction
    "hello"
  RX

  File.write(reactor_rx_file, content)
end

When('the Reactor loads the test rx file') do
  reactor.load('test_reactor_bdd')
end
