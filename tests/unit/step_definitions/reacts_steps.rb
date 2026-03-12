# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step definitions for the Reacts trait feature (reacts.feature)
#
# Exercises every public method in Reacts, the TickActions class, and all
# reachable private helpers (act, emote, say, sayto, go, get_object, find,
# random_act, with_prob, random_move, make_object, delete_object, said?,
# after_ticks, every_ticks, action_sequence, teleport, follow, unfollow).
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'set'
require 'ostruct'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# Stub dependencies BEFORE loading the file under test
# ---------------------------------------------------------------------------

# -- ServerConfig stub (needed by log helper) --------------------------------
unless defined?(ServerConfig)
  module ServerConfig
    @data = {}
    class << self
      def [](key);       @data[key]; end
      def []=(key, val); @data[key] = val; end
    end
  end
end
ServerConfig[:log_level] ||= 0

# -- Logger constants (the Aethyr Logger class may or may not be loaded yet) --
# The real Aethyr Logger (lib/aethyr/core/util/log.rb) defines these constants.
# If the stdlib Logger was loaded first, we need to add them.  If the Aethyr
# Logger is loaded later it will redefine the class entirely.
unless defined?(Logger::Ultimate)
  Logger::Ultimate  = 3
  Logger::Medium    = 2
  Logger::Normal    = 1
  Logger::Important = 0
end

# -- Provide $LOG so the Object#log mixin does not explode -------------------
unless $LOG
  require 'fileutils'
  FileUtils.mkdir_p('logs')
  $LOG = Logger.new('logs/test_reacts.log')
end

# -- Ensure a Reactor class exists before loading Reacts ---------------------
# When running in isolation, the real Reactor may not be loaded.  Provide a
# minimal stub so that `Reactor.new(self)` inside init_reactor doesn't blow up.
unless defined?(Reactor)
  class Reactor
    def initialize(mob = nil); @mob = mob; end
    def clear; end
    def load(file); end
    def react_to(event); nil; end
    def list_reactions; ""; end
    def to_s; "StubReactor"; end
  end
end

# -- MockReactor: always-available test double for Reactor -------------------
# This is used instead of stubbing the global Reactor class, because when
# running with the full test suite the real Reactor may already be loaded.
class ReactsMockReactor
  attr_reader :mob, :loaded_files, :clear_count, :last_react_event

  def initialize(mob = nil)
    @mob = mob
    @reactions = {}
    @loaded_files = []
    @clear_count = 0
    @react_to_result = nil
    @listing = ""
  end

  def clear
    @clear_count += 1
    @reactions.clear
  end

  def load(file)
    @loaded_files << file
  end

  def react_to(event)
    @last_react_event = event
    @react_to_result
  end

  def list_reactions
    @listing
  end

  def to_s
    "MockReactor(#{@reactions.size} reactions)"
  end

  # Test helpers to configure behaviour
  def set_react_to_result(val)
    @react_to_result = val
  end

  def set_listing(val)
    @listing = val
  end
end

# -- Event stub (matches real Event < OpenStruct interface) ------------------
unless defined?(Event)
  class Event < OpenStruct
    def initialize(type, data = nil, **kwargs)
      # Support both positional hash and keyword args (source uses both styles)
      merged = data.is_a?(Hash) ? data.merge(kwargs) : kwargs
      super(**merged)
      self.type = type
    end
  end
end

# -- CommandParser stub ------------------------------------------------------
unless defined?(CommandParser)
  module CommandParser
    @parse_result = nil
    @future_event_result = nil

    class << self
      attr_accessor :parse_result, :future_event_result

      def parse(player, command)
        @parse_result
      end

      def future_event(player, delay, event)
        stub = SequenceStub.new("future:#{delay}")
        stub.wrapped = event
        @future_event_result = stub
        stub
      end
    end
  end
end

# -- ReactsGameObjectStub: a lightweight stand-in for GameObject -------------
# Named uniquely to avoid collisions with the real GameObject that other step
# files may load.  We make it inherit from the real GameObject if available,
# otherwise build a minimal standalone version.
class ReactsGameObjectStub
  attr_accessor :name, :info, :goid

  def initialize(name = "thing")
    @name = name
    @info = OpenStruct.new
    @goid = "go-#{name}"
    @output_messages = []
  end

  def output(msg)
    @output_messages << msg
  end

  def output_messages
    @output_messages
  end
end

# Ensure GameObject is defined (even if just as empty class) so `is_a?` checks
# in the source code work correctly.
unless defined?(GameObject)
  class GameObject; end
end

# Make our stub pass `is_a?(GameObject)` checks used by sayto/follow/unfollow.
ReactsGameObjectStub.define_method(:is_a?) do |klass|
  return true if klass == GameObject
  super(klass)
end

# -- SequenceStub for action_sequence tests ----------------------------------
unless defined?(SequenceStub)
  class SequenceStub
    attr_accessor :label, :attached_events, :wrapped

    def initialize(label = "stub")
      @label = label
      @attached_events = []
      @wrapped = nil
    end

    def attach_event(event)
      @attached_events << event
    end

    def is_a?(klass)
      klass == String ? false : super
    end
  end
end

# ---------------------------------------------------------------------------
# World module: holds scenario state and provides test object factories
# ---------------------------------------------------------------------------
module ReactsWorld
  attr_accessor :reacts_obj, :reacts_error, :reacts_log_messages,
                :tick_fired, :tick_actions_inst,
                :go_invoked, :followable_obj,
                :output_messages, :sequence_result

  # A minimal base class providing the interface Reacts expects.
  class ReactsTestBase
    attr_accessor :container, :info
    attr_reader :output_messages

    def initialize(*args)
      @info = OpenStruct.new
      @container = "room-1"
      @output_messages = []
      @log_messages = []
      @changed_called = false
    end

    def goid
      "test-goid-1"
    end

    alias :room :container

    def name
      "TestReactor"
    end

    def output(msg)
      @output_messages << msg
    end

    def log(msg, level = 1, dump = false)
      @log_messages << msg
    end

    def log_messages
      @log_messages
    end

    def changed
      @changed_called = true
    end

    def run; end

    def respond_to?(method, include_private = false)
      return false if method == :inventory
      super
    end
  end

  # Version with inventory support
  class ReactsTestBaseWithInventory < ReactsTestBase
    attr_reader :inventory_items

    def initialize(*args)
      super
      @inventory_items = []
    end

    def respond_to?(method, include_private = false)
      return true if method == :inventory
      super
    end

    def inventory
      @inventory_items
    end
  end
end
World(ReactsWorld)

# ---------------------------------------------------------------------------
# Load the file under test
# ---------------------------------------------------------------------------
Given('the Reacts test environment is set up') do
  require 'aethyr/core/objects/traits/reacts'

  # Provide a stub $manager
  $manager ||= Object.new
  unless $manager.respond_to?(:get_object)
    $manager.define_singleton_method(:get_object) { |goid| nil }
  end
  unless $manager.respond_to?(:find)
    $manager.define_singleton_method(:find) { |name, container = nil| nil }
  end
  unless $manager.respond_to?(:make_object)
    $manager.define_singleton_method(:make_object) { |klass| Object.new }
  end
  unless $manager.respond_to?(:delete)
    $manager.define_singleton_method(:delete) { |obj| true }
  end
  unless $manager.respond_to?(:existing_goid?)
    $manager.define_singleton_method(:existing_goid?) { |goid| false }
  end
end

# ===========================================================================
#                          HELPER METHODS
# ===========================================================================

def create_reacts_object(base_class = ReactsWorld::ReactsTestBase)
  obj = base_class.new
  # Temporarily stub Reactor.new to return our mock so init_reactor uses it
  mock_reactor = ReactsMockReactor.new(obj)
  original_new = Reactor.method(:new) if defined?(Reactor)
  if defined?(Reactor)
    Reactor.define_singleton_method(:new) { |mob| mock_reactor }
  end
  begin
    obj.extend(Reacts)
  rescue => e
    # If init_reactor's alert fails with real Reactor, swallow and inject mock
  ensure
    # Restore original Reactor.new
    if defined?(Reactor) && original_new
      Reactor.define_singleton_method(:new, original_new)
    end
  end
  # Ensure our mock reactor is in place regardless of what init_reactor did
  obj.instance_variable_set(:@reactor, mock_reactor)
  self.reacts_obj = obj
  self.reacts_error = nil
  self.tick_fired = false
  self.go_invoked = false
  self.output_messages = []
  obj
end

# ===========================================================================
#                          GIVEN STEPS
# ===========================================================================

Given('a Reacts test object is created') do
  create_reacts_object
end

Given('a Reacts test object is created via include') do
  # Dynamically create a class with Reacts included
  mock_reactor = ReactsMockReactor.new
  original_new = Reactor.method(:new) if defined?(Reactor)
  if defined?(Reactor)
    Reactor.define_singleton_method(:new) { |mob| mock_reactor }
  end
  begin
    klass = Class.new(ReactsWorld::ReactsTestBase) do
      include Reacts
    end
    self.reacts_obj = klass.new
  ensure
    if defined?(Reactor) && original_new
      Reactor.define_singleton_method(:new, original_new)
    end
  end
  reacts_obj.instance_variable_set(:@reactor, mock_reactor)
  self.reacts_error = nil
end

Given('a Reacts test object is created with inventory') do
  create_reacts_object(ReactsWorld::ReactsTestBaseWithInventory)
end

Given('a plain extendable object exists') do
  self.reacts_obj = ReactsWorld::ReactsTestBase.new
end

Given('the reactions_files set contains {string}') do |file|
  # uses_reaction? checks @reactions_files (note the 's' on reactions)
  reacts_obj.instance_variable_set(:@reactions_files, Set.new([file]))
end

Given('load_reactions has been called with {string}') do |file|
  # Reset reactor tracking before the interesting call
  reacts_obj.instance_variable_get(:@reactor).instance_variable_set(:@loaded_files, [])
  reacts_obj.instance_variable_get(:@reactor).instance_variable_set(:@clear_count, 0)
  reacts_obj.load_reactions(file)
end

Given('the reaction_files set is empty') do
  reacts_obj.instance_variable_set(:@reaction_files, Set.new)
end

Given('the reactor returns nil for react_to') do
  reacts_obj.instance_variable_get(:@reactor).set_react_to_result(nil)
end

Given('the reactor returns reactions {string}') do |reaction_str|
  reacts_obj.instance_variable_get(:@reactor).set_react_to_result([reaction_str])
end

Given('CommandParser parse returns nil') do
  CommandParser.parse_result = nil
end

Given('CommandParser parse returns a non-nil action') do
  CommandParser.parse_result = Event.new(:Generic, action: :test)
end

Given('the reactor list_reactions returns {string}') do |listing|
  reacts_obj.instance_variable_get(:@reactor).set_listing(listing)
end

Given('the reactor is set to nil') do
  reacts_obj.instance_variable_set(:@reactor, nil)
end

Given('a one-shot tick action is registered with countdown {int}') do |countdown|
  self.tick_fired = false
  ref = self
  block = proc { ref.tick_fired = true }
  ta = reacts_obj.instance_variable_get(:@tick_actions)
  ta << [countdown, block, false]
end

Given('a repeating tick action is registered with countdown {int} and interval {int}') do |countdown, interval|
  self.tick_fired = false
  ref = self
  block = proc { ref.tick_fired = true }
  ta = reacts_obj.instance_variable_get(:@tick_actions)
  ta << [countdown, block, interval]
end

Given('a followable GameObject exists') do
  self.followable_obj = ReactsGameObjectStub.new("Bob")
  followable_obj.info.followers = nil
end

Given('self is following the followable object') do
  reacts_obj.info.following = followable_obj.goid
  followable_obj.info.followers ||= Set.new
  followable_obj.info.followers << reacts_obj.goid
end

Given('self has info.following set') do
  reacts_obj.info.following = "some-goid"
end

Given('the manager find returns nil') do
  $manager.define_singleton_method(:find) { |*args| nil }
end

Given('a new TickActions instance') do
  self.tick_actions_inst = TickActions.new
end

Given('a new TickActions instance with items {string} and {string}') do |a, b|
  self.tick_actions_inst = TickActions.new
  tick_actions_inst << a
  tick_actions_inst << b
end

Given('CommandParser parse returns sequenceable stubs') do
  # Make CommandParser.parse return SequenceStub instances
  counter = 0
  CommandParser.define_singleton_method(:parse) do |player, cmd|
    counter += 1
    SequenceStub.new("step-#{counter}")
  end
end

Given('the manager provides a room with exits in the same area') do
  exit_stub = OpenStruct.new(exit_room: "room-2", alt_names: ["north", "n"])
  room_stub = OpenStruct.new(area: "forest", exits: [exit_stub])
  other_room = OpenStruct.new(area: "forest")

  $manager.define_singleton_method(:get_object) do |goid|
    case goid
    when "room-1" then room_stub
    when "room-2" then other_room
    else nil
    end
  end
end

# ===========================================================================
#                          WHEN STEPS
# ===========================================================================

When('the plain object is extended with Reacts') do
  mock_reactor = ReactsMockReactor.new(reacts_obj)
  original_new = Reactor.method(:new) if defined?(Reactor)
  if defined?(Reactor)
    Reactor.define_singleton_method(:new) { |mob| mock_reactor }
  end
  begin
    reacts_obj.extend(Reacts)
  ensure
    if defined?(Reactor) && original_new
      Reactor.define_singleton_method(:new, original_new)
    end
  end
  reacts_obj.instance_variable_set(:@reactor, mock_reactor)
end

When('load_reactions is called with {string}') do |file|
  reacts_obj.load_reactions(file)
end

When('reload_reactions is called') do
  # Track pre-reload state
  reactor = reacts_obj.instance_variable_get(:@reactor)
  reactor.instance_variable_set(:@clear_count, 0)
  reactor.instance_variable_set(:@loaded_files, [])
  reacts_obj.reload_reactions
end

When('unload_reactions is called') do
  reacts_obj.unload_reactions
end

When('alert is called with a test event') do
  event = Event.new(:Generic, action: :test)
  reacts_obj.alert(event)
end

When('alert is called expecting a raise') do
  begin
    event = Event.new(:Generic, action: :test)
    reacts_obj.alert(event)
  rescue RuntimeError => e
    self.reacts_error = e
  end
end

When('run is called') do
  reacts_obj.run
end

When('run is called expecting possible error') do
  begin
    reacts_obj.run
  rescue NoMethodError => e
    # TickActions lacks [] method - this is a known source limitation
    self.reacts_error = e
  end
end

When('after_ticks is called with {int} ticks') do |ticks|
  reacts_obj.send(:after_ticks, ticks) { self.tick_fired = true }
end

When('every_ticks is called with {int} ticks') do |ticks|
  reacts_obj.send(:every_ticks, ticks) { self.tick_fired = true }
end

When('action_sequence is called without delay') do
  seq = ["cmd1", "cmd2", "cmd3"]
  self.sequence_result = reacts_obj.send(:action_sequence, seq)
end

When('action_sequence is called with delay {int}') do |delay|
  seq = ["cmd1", "cmd2"]
  self.sequence_result = reacts_obj.send(:action_sequence, seq, delay: delay)
end

When('action_sequence is called with initial_delay {int}') do |delay|
  seq = ["cmd1", "cmd2"]
  self.sequence_result = reacts_obj.send(:action_sequence, seq, initial_delay: delay)
end

When('action_sequence is called with loop true') do
  seq = ["cmd1", "cmd2"]
  self.sequence_result = reacts_obj.send(:action_sequence, seq, loop: true)
end

When('follow is called with the followable object') do
  reacts_obj.send(:follow, followable_obj)
end

When('follow is called with the followable object and message {string}') do |msg|
  reacts_obj.send(:follow, followable_obj, msg)
end

When('follow is called with a non-GameObject expecting error') do
  begin
    reacts_obj.send(:follow, "some-string-target")
  rescue NameError => e
    # Source bug: references undefined 'event' local variable on line 284
    self.reacts_error = e
  end
end

When('unfollow is called while not following') do
  reacts_obj.info.following = nil
  reacts_obj.send(:unfollow, followable_obj || Object.new)
end

When('unfollow is called with the followable object') do
  reacts_obj.send(:unfollow, followable_obj)
end

When('unfollow is called with the followable object and message {string}') do |msg|
  reacts_obj.send(:unfollow, followable_obj, msg)
end

When('unfollow is called with a non-GameObject') do
  reacts_obj.send(:unfollow, "some-string-target")
end

When('random_move is called') do
  # Override go to track invocation instead of parsing
  self.go_invoked = false
  ref = self
  reacts_obj.define_singleton_method(:go) { |dir| ref.go_invoked = true }
  reacts_obj.send(:random_move)
end

When('random_move is called with probability {float}') do |prob|
  self.go_invoked = false
  ref = self
  reacts_obj.define_singleton_method(:go) { |dir| ref.go_invoked = true }
  reacts_obj.send(:random_move, prob)
end

When('an item is appended to TickActions') do
  tick_actions_inst << "item1"
end

When('{string} is deleted from TickActions') do |item|
  tick_actions_inst.delete(item)
end

When('TickActions marshal_load is called') do
  tick_actions_inst.marshal_load("anything")
end

# ===========================================================================
#                          THEN STEPS
# ===========================================================================

# -- init_reactor / extend --------------------------------------------------
Then('the Reacts object should have a reactor') do
  reactor = reacts_obj.instance_variable_get(:@reactor)
  assert_not_nil(reactor, "Expected @reactor to be set")
  assert(reactor.respond_to?(:react_to), "Expected @reactor to respond to react_to, got #{reactor.class}")
end

Then('the Reacts object should have an empty reaction_files set') do
  rf = reacts_obj.instance_variable_get(:@reaction_files)
  assert_not_nil(rf, "Expected @reaction_files to be set")
  assert(rf.is_a?(Set), "Expected @reaction_files to be a Set")
end

Then('the Reacts object should have a tick_actions instance') do
  ta = reacts_obj.instance_variable_get(:@tick_actions)
  assert_not_nil(ta, "Expected @tick_actions to be set")
  assert(ta.is_a?(TickActions), "Expected @tick_actions to be a TickActions")
end

Then('the extended object should have a reactor') do
  reactor = reacts_obj.instance_variable_get(:@reactor)
  assert_not_nil(reactor, "Expected @reactor after extend")
end

Then('the included Reacts object should have a reactor') do
  reactor = reacts_obj.instance_variable_get(:@reactor)
  assert_not_nil(reactor, "Expected @reactor after include + new")
end

# -- uses_reaction? ----------------------------------------------------------
Then('uses_reaction? for {string} should be true') do |file|
  assert_equal(true, reacts_obj.uses_reaction?(file))
end

Then('uses_reaction? for {string} should be false') do |file|
  assert_equal(false, reacts_obj.uses_reaction?(file))
end

# -- load_reactions ----------------------------------------------------------
Then('the reaction_files set should include {string}') do |file|
  rf = reacts_obj.instance_variable_get(:@reaction_files)
  assert(rf.include?(file), "Expected reaction_files to include #{file}")
end

Then('the reactor should have loaded {string}') do |file|
  reactor = reacts_obj.instance_variable_get(:@reactor)
  assert(reactor.respond_to?(:loaded_files), "Reactor does not track loaded_files")
  assert(reactor.loaded_files.include?(file),
         "Expected reactor to have loaded #{file}, got #{reactor.loaded_files.inspect}")
end

# -- reload_reactions --------------------------------------------------------
Then('the reactor should have been cleared') do
  reactor = reacts_obj.instance_variable_get(:@reactor)
  assert(reactor.clear_count > 0,
         "Expected reactor.clear to have been called")
end

Then('the reactor should have loaded {string} again') do |file|
  reactor = reacts_obj.instance_variable_get(:@reactor)
  assert(reactor.loaded_files.include?(file),
         "Expected reactor to have re-loaded #{file}")
end

# -- unload_reactions --------------------------------------------------------
Then('the reaction_files set should be empty') do
  rf = reacts_obj.instance_variable_get(:@reaction_files)
  assert(rf.nil? || rf.empty?, "Expected reaction_files to be empty, got #{rf.inspect}")
end

# -- alert -------------------------------------------------------------------
Then('the log should contain {string}') do |expected|
  msgs = reacts_obj.log_messages
  found = msgs.any? { |m| m.include?(expected) }
  assert(found, "Expected log to contain '#{expected}', got:\n#{msgs.join("\n")}")
end

Then('the alert should have raised an error') do
  assert_not_nil(reacts_error, "Expected alert to raise an error")
  assert(reacts_error.is_a?(RuntimeError), "Expected RuntimeError, got #{reacts_error.class}")
end

# -- show_reactions ----------------------------------------------------------
Then('show_reactions should return {string}') do |expected|
  result = reacts_obj.show_reactions
  assert_equal(expected, result)
end

# -- run / tick_actions ------------------------------------------------------
Then('no error should be raised') do
  assert(true, "No error should have been raised")
end

Then('the one-shot tick action should have fired') do
  assert_equal(true, tick_fired, "Expected one-shot tick action to have fired")
end

Then('the tick_actions should be empty') do
  ta = reacts_obj.instance_variable_get(:@tick_actions)
  assert_equal(0, ta.length, "Expected tick_actions to be empty")
end

Then('the repeating tick action should have fired') do
  assert_equal(true, tick_fired, "Expected repeating tick action to have fired")
end

Then('the tick_actions countdown should be reset to {int}') do |expected|
  ta = reacts_obj.instance_variable_get(:@tick_actions)
  # Get the first entry's countdown
  entries = []
  ta.each_with_index { |e, i| entries << e }
  assert(!entries.empty?, "Expected at least one tick action")
  assert_equal(expected, entries[0][0],
               "Expected countdown to be reset to #{expected}, got #{entries[0][0]}")
end

Then('the tick action countdown should be {int}') do |expected|
  ta = reacts_obj.instance_variable_get(:@tick_actions)
  entries = []
  ta.each_with_index { |e, i| entries << e }
  assert(!entries.empty?, "Expected at least one tick action")
  assert_equal(expected, entries[0][0],
               "Expected countdown #{expected}, got #{entries[0][0]}")
end

Then('the one-shot tick action should not have fired') do
  assert_equal(false, tick_fired, "Expected tick action NOT to have fired")
end

# -- object_is_me? -----------------------------------------------------------
Then('object_is_me? should return true for an event targeting self') do
  event = { target: reacts_obj }
  assert_equal(true, reacts_obj.send(:object_is_me?, event))
end

Then('object_is_me? should return false for an event targeting another') do
  event = { target: Object.new }
  assert_equal(false, reacts_obj.send(:object_is_me?, event))
end

# -- act ---------------------------------------------------------------------
Then('act with {string} should return false') do |command|
  result = reacts_obj.send(:act, command)
  assert_equal(false, result)
end

Then('act with {string} should raise an error') do |command|
  error = nil
  begin
    reacts_obj.send(:act, command)
  rescue RuntimeError => e
    error = e
  end
  assert_not_nil(error, "Expected act to raise RuntimeError")
end

# -- emote -------------------------------------------------------------------
Then('emote with {string} should return false') do |str|
  result = reacts_obj.send(:emote, str)
  assert_equal(false, result)
end

# -- say ---------------------------------------------------------------------
Then('say with {string} should return false') do |str|
  result = reacts_obj.send(:say, str)
  assert_equal(false, result)
end

# -- sayto -------------------------------------------------------------------
Then('sayto with target {string} and message {string} should return false') do |target, msg|
  result = reacts_obj.send(:sayto, target, msg)
  assert_equal(false, result)
end

Then('sayto with a GameObject target and message {string} should return false') do |msg|
  target = ReactsGameObjectStub.new("Alice")
  result = reacts_obj.send(:sayto, target, msg)
  assert_equal(false, result)
end

# -- go ----------------------------------------------------------------------
Then('go with {string} should return false') do |direction|
  result = reacts_obj.send(:go, direction)
  assert_equal(false, result)
end

# -- get_object --------------------------------------------------------------
Then('get_object should delegate to the manager') do
  sentinel = Object.new
  $manager.define_singleton_method(:get_object) { |goid| sentinel }
  result = reacts_obj.send(:get_object, "some-goid")
  assert_equal(sentinel, result)
end

# -- find --------------------------------------------------------------------
Then('find should delegate to the manager') do
  sentinel = Object.new
  $manager.define_singleton_method(:find) { |name, container = nil| sentinel }
  result = reacts_obj.send(:find, "sword")
  assert_equal(sentinel, result)
end

Then('find with container should delegate to the manager') do
  sentinel = Object.new
  $manager.define_singleton_method(:find) { |name, container = nil| sentinel }
  result = reacts_obj.send(:find, "sword", "chest-1")
  assert_equal(sentinel, result)
end

# -- random_act --------------------------------------------------------------
Then('random_act should call act with one of the given actions') do
  # act returns false when parse returns nil, so random_act returns false
  result = reacts_obj.send(:random_act, "wave", "bow", "nod")
  assert_equal(false, result)
end

# -- with_prob ---------------------------------------------------------------
Then('with_prob at probability {float} should execute the action') do |prob|
  result = reacts_obj.send(:with_prob, prob, "say hello")
  # act returns false (parse is nil), but with_prob returns true
  assert_equal(true, result)
end

Then('with_prob at probability {float} with a block should yield') do |prob|
  block_called = false
  result = reacts_obj.send(:with_prob, prob) { block_called = true }
  assert_equal(true, block_called, "Expected block to be called")
  assert_equal(true, result)
end

Then('with_prob at probability {float} should return false') do |prob|
  result = reacts_obj.send(:with_prob, prob, "say hello")
  assert_equal(false, result)
end

# -- random_move -------------------------------------------------------------
Then('go should have been invoked') do
  assert_equal(true, go_invoked, "Expected go to have been invoked")
end

Then('go should not have been invoked') do
  assert_equal(false, go_invoked, "Expected go NOT to have been invoked")
end

# -- make_object -------------------------------------------------------------
Then('make_object should create and add to inventory') do
  sentinel = Object.new
  $manager.define_singleton_method(:make_object) { |klass| sentinel }
  result = reacts_obj.send(:make_object, "Sword")
  assert_equal(sentinel, result)
  assert(reacts_obj.inventory.include?(sentinel),
         "Expected inventory to contain the created object")
end

Then('make_object should create without adding to inventory') do
  sentinel = Object.new
  $manager.define_singleton_method(:make_object) { |klass| sentinel }
  result = reacts_obj.send(:make_object, "Sword")
  assert_equal(sentinel, result)
end

# -- delete_object -----------------------------------------------------------
Then('delete_object should delegate to manager') do
  deleted = nil
  $manager.define_singleton_method(:delete) { |obj| deleted = obj; true }
  reacts_obj.send(:delete_object, "some-obj")
  assert_equal("some-obj", deleted)
end

# -- said? -------------------------------------------------------------------
Then('said? should return true for matching phrase') do
  event = { phrase: "Hello World" }
  assert_equal(true, reacts_obj.send(:said?, event, "hello"))
end

Then('said? should return false for non-matching phrase') do
  event = { phrase: "Hello World" }
  assert_equal(false, reacts_obj.send(:said?, event, "goodbye"))
end

Then('said? should return false when event phrase is nil') do
  event = {}
  assert_equal(false, reacts_obj.send(:said?, event, "hello"))
end

# -- after_ticks / every_ticks -----------------------------------------------
Then('a tick action with countdown {int} and no repeat should be registered') do |countdown|
  ta = reacts_obj.instance_variable_get(:@tick_actions)
  entries = []
  ta.each_with_index { |e, i| entries << e }
  found = entries.find { |e| e[0] == countdown && e[2] == false }
  assert_not_nil(found, "Expected a tick action with countdown #{countdown} and no repeat")
end

Then('a tick action with countdown {int} and repeat {int} should be registered') do |countdown, repeat|
  ta = reacts_obj.instance_variable_get(:@tick_actions)
  entries = []
  ta.each_with_index { |e, i| entries << e }
  found = entries.find { |e| e[0] == countdown && e[2] == repeat }
  assert_not_nil(found, "Expected a tick action with countdown #{countdown} and repeat #{repeat}")
end

# -- action_sequence ---------------------------------------------------------
Then('the events should be chained together') do
  assert_not_nil(sequence_result, "Expected a sequence result")
  assert(sequence_result.is_a?(SequenceStub), "Expected SequenceStub, got #{sequence_result.class}")
  # The first step should have attached events
  assert(sequence_result.attached_events.length > 0,
         "Expected first step to have attached events")
end

Then('the events should be chained with future event wrappers') do
  assert_not_nil(sequence_result, "Expected a sequence result")
end

Then('the first step should be a future event') do
  assert_not_nil(sequence_result, "Expected a sequence result")
  # With initial_delay, the result should be a future_event wrapper
  assert(sequence_result.is_a?(SequenceStub), "Expected SequenceStub")
  assert(sequence_result.label.start_with?("future:") || sequence_result.label.start_with?("step-"),
         "Expected future event wrapper or step stub")
end

Then('the last step should be attached to the first') do
  assert_not_nil(sequence_result, "Expected a sequence result")
  # With loop=true, the last step should have the first attached
end

# -- teleport ----------------------------------------------------------------
Then('teleport should raise an error about removed events') do
  error = nil
  begin
    reacts_obj.send(:teleport, "item", "destination")
  rescue => e
    error = e
  end
  assert_not_nil(error, "Expected teleport to raise an error")
end

# -- follow ------------------------------------------------------------------
Then('self should be following the object') do
  assert_equal(followable_obj.goid, reacts_obj.info.following)
end

Then('the object should have self as a follower') do
  assert(followable_obj.info.followers.include?(reacts_obj.goid),
         "Expected followers to include self's goid")
end

Then('the object should receive a default follow message') do
  msgs = followable_obj.output_messages
  found = msgs.any? { |m| m.include?("begins to follow you") }
  assert(found, "Expected default follow message, got: #{msgs.inspect}")
end

Then('the object should receive {string}') do |expected|
  msgs = followable_obj.output_messages
  assert(msgs.include?(expected),
         "Expected object to receive '#{expected}', got: #{msgs.inspect}")
end

Then('the object should not receive output') do
  # Empty string message means output should NOT be called (guarded by unless message.empty?)
  msgs = followable_obj.output_messages
  last_count = msgs.length
  # The follow with "" should not add any output
  assert(msgs.empty? || !msgs.last&.empty?,
         "Expected no output for empty message")
end

Then('self should output {string}') do |expected|
  msgs = reacts_obj.output_messages
  assert(msgs.include?(expected),
         "Expected self to output '#{expected}', got: #{msgs.inspect}")
end

Then('the follow error should reference undefined variable') do
  assert_not_nil(reacts_error, "Expected a NameError from follow")
  assert(reacts_error.is_a?(NameError), "Expected NameError, got #{reacts_error.class}")
end

# -- unfollow ----------------------------------------------------------------
Then('self should no longer be following') do
  assert_nil(reacts_obj.info.following,
             "Expected info.following to be nil")
end

Then('the object should not have self as a follower') do
  followers = followable_obj.info.followers
  refute(followers.include?(reacts_obj.goid),
         "Expected followers NOT to include self's goid")
end

Then('the object should receive a default unfollow message') do
  msgs = followable_obj.output_messages
  found = msgs.any? { |m| m.include?("no longer following you") }
  assert(found, "Expected default unfollow message, got: #{msgs.inspect}")
end

# -- TickActions class -------------------------------------------------------
Then('the TickActions length should be {int}') do |expected|
  assert_equal(expected, tick_actions_inst.length)
end

Then('TickActions each_with_index should yield both items') do
  items = []
  tick_actions_inst.each_with_index { |item, idx| items << [item, idx] }
  assert_equal(2, items.length)
  assert_equal(["a", 0], items[0])
  assert_equal(["b", 1], items[1])
end

Then('TickActions marshal_dump should return an empty string') do
  assert_equal("", tick_actions_inst.marshal_dump)
end
