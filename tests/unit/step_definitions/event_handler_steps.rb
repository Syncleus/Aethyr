# frozen_string_literal: true
###############################################################################
# Step definitions for EventHandler component coverage.                       #
###############################################################################
require 'test/unit/assertions'
require 'ostruct'

World(Test::Unit::Assertions)

###############################################################################
# World module – scenario-scoped state                                        #
###############################################################################
module EvhWorld
  attr_accessor :evh_handler, :evh_handled_events, :evh_log_messages,
                :evh_dispatch_calls, :evh_future_events, :evh_last_event,
                :evh_external_mutex
end
World(EvhWorld)

###############################################################################
# Lightweight stubs – avoid loading the full application                      #
###############################################################################

# Ensure ServerConfig exists (needed by Logger / log helper)
unless defined?(::ServerConfig)
  module ::ServerConfig
    @data = {}
    class << self
      def [](key);       @data[key]; end
      def []=(key, val); @data[key] = val; end
    end
  end
end
ServerConfig[:log_level] ||= 1

# Provide a lightweight LOG double so that the `log` helper from
# lib/aethyr/core/util/log.rb can function without touching the filesystem.
class EvhLogDouble
  attr_reader :entries

  def initialize
    @entries = []
  end

  def add(severity, msg = nil, progname = nil, dump_log: false)
    @entries << msg.to_s if msg
  end

  def dump; end
  def clear; end
end

# Install a global LOG double before anything tries to use `log`.
$LOG ||= EvhLogDouble.new

# Make sure the `log` helper is available on Object (idempotent).
unless Object.private_method_defined?(:log)
  class Object
    private
    def log(msg, *_args)
      $LOG.add(1, msg.to_s) if $LOG.respond_to?(:add)
    end
  end
end

# ---------------------------------------------------------------------------
# Stub out the heavy transitive requires so we can load event_handler.rb
# without pulling in the entire game.
# ---------------------------------------------------------------------------
%w[
  aethyr/core/util/all-commands
  aethyr/extensions/skills
].each do |lib|
  $LOADED_FEATURES << lib unless $LOADED_FEATURES.include?(lib)
end

# Now load the file under test and its direct dependency (Event).
require 'aethyr/core/event'
require 'aethyr/core/components/event_handler'

# ---------------------------------------------------------------------------
# Test module that records dispatched actions (used for line 69 coverage).
# ---------------------------------------------------------------------------
module EvhTestDispatch
  @calls = []

  class << self
    attr_reader :calls

    def reset!
      @calls = []
    end

    def evh_test_action(event, player, room)
      @calls << { event: event, player: player, room: room }
    end
  end
end

# ---------------------------------------------------------------------------
# Test module that raises a generic (non-NameError) exception (lines 74-75).
# ---------------------------------------------------------------------------
class EvhTestRuntimeError < RuntimeError; end

module EvhTestRaising
  class << self
    def evh_raising_action(_event, _player, _room)
      raise EvhTestRuntimeError, "boom from EvhTestRaising"
    end
  end
end

# ---------------------------------------------------------------------------
# Tiny player stub for testing.
# ---------------------------------------------------------------------------
class EvhPlayerStub
  attr_accessor :room, :goid, :name

  def initialize
    @goid = "evh_player_goid_42"
    @room = "evh_room_goid_1"
    @name = "EvhTestPlayer"
  end

  def output(_msg, *_args); end
end

# ---------------------------------------------------------------------------
# Tiny manager stub.
# ---------------------------------------------------------------------------
class EvhManagerStub
  attr_reader :future_events

  def initialize
    @future_events = []
  end

  def find(_goid)
    OpenStruct.new(name: "Test Room", goid: "evh_room_goid_1")
  end

  def future_event(event)
    @future_events << event
  end

  # Some code paths in the broader codebase call get_object; alias for safety.
  alias get_object find
end

###############################################################################
# Given steps                                                                 #
###############################################################################
Given('a stubbed EventHandler environment') do
  # Reset shared tracking state
  EvhTestDispatch.reset!
  @evh_log_messages  = []
  @evh_handled_events = []
  @evh_dispatch_calls = []
  @evh_future_events  = []
  @evh_last_event     = nil
  @evh_external_mutex = nil

  # Install a fresh LOG double so we can inspect messages
  $LOG = EvhLogDouble.new

  # Install the manager stub
  $manager = EvhManagerStub.new

  # Create the handler under test
  @evh_handler = EventHandler.new(nil)

  # Patch handle_event tracking for run-method tests: we wrap the original
  # so we can count invocations without changing dispatch behaviour.
  original_handle = @evh_handler.method(:handle_event)
  handled = @evh_handled_events
  @evh_handler.define_singleton_method(:handle_event) do |event|
    handled << event
    original_handle.call(event)
  end
end

Given('an evh event is enqueued') do
  player = EvhPlayerStub.new
  event  = Event.new(:EvhTestDispatch, player: player, action: :evh_test_action)
  @evh_handler.event_queue.push(event)
end

Given('{int} evh events are enqueued') do |count|
  player = EvhPlayerStub.new
  count.times do
    event = Event.new(:EvhTestDispatch, player: player, action: :evh_test_action)
    @evh_handler.event_queue.push(event)
  end
end

Given('the evh mutex is already locked') do
  # Access the internal mutex and lock it from this thread to simulate contention.
  # We use instance_variable_get because @mutex is not exposed via accessor.
  mutex = @evh_handler.instance_variable_get(:@mutex)
  mutex.lock
  @evh_external_mutex = mutex  # remember so we can unlock in cleanup
end

###############################################################################
# When steps                                                                  #
###############################################################################
When('I call evh stop') do
  @evh_handler.stop
end

When('I call evh start') do
  @evh_handler.start
end

When('I call evh run') do
  @evh_handler.run
  # Unlock the mutex if we locked it externally (contention scenario)
  if @evh_external_mutex && @evh_external_mutex.owned?
    @evh_external_mutex.unlock
    @evh_external_mutex = nil
  end
end

When('I call evh handle_event with a valid event') do
  player = EvhPlayerStub.new
  @evh_last_event = Event.new(:EvhTestDispatch, player: player, action: :evh_test_action)
  @evh_handler.handle_event(@evh_last_event)
end

When('I call evh handle_event with a string argument') do
  @evh_handler.handle_event("this is not an Event")
end

When('I call evh handle_event with a dispatchable event') do
  player = EvhPlayerStub.new
  @evh_last_event = Event.new(:EvhTestDispatch, player: player, action: :evh_test_action)
  @evh_handler.handle_event(@evh_last_event)
end

When('I call evh handle_event with at set to me') do
  player = EvhPlayerStub.new
  @evh_last_event = Event.new(:EvhTestDispatch,
                               player: player,
                               action: :evh_test_action,
                               at: 'me')
  @evh_handler.handle_event(@evh_last_event)
end

When('I call evh handle_event with object set to me') do
  player = EvhPlayerStub.new
  @evh_last_event = Event.new(:EvhTestDispatch,
                               player: player,
                               action: :evh_test_action,
                               object: 'me')
  @evh_handler.handle_event(@evh_last_event)
end

When('I call evh handle_event with target set to me') do
  player = EvhPlayerStub.new
  @evh_last_event = Event.new(:EvhTestDispatch,
                               player: player,
                               action: :evh_test_action,
                               target: 'me')
  @evh_handler.handle_event(@evh_last_event)
end

When('I call evh handle_event with a Future event') do
  player = EvhPlayerStub.new
  @evh_last_event = Event.new(:Future,
                               player: player,
                               action: :some_future_action)
  @evh_handler.handle_event(@evh_last_event)
end

When('I call evh handle_event with an unknown module type') do
  player = EvhPlayerStub.new
  @evh_last_event = Event.new(:EvhNonExistentModule99,
                               player: player,
                               action: :whatever)
  @evh_handler.handle_event(@evh_last_event)
end

When('I call evh handle_event with a raising module type') do
  player = EvhPlayerStub.new
  @evh_last_event = Event.new(:EvhTestRaising,
                               player: player,
                               action: :evh_raising_action)
  @evh_handler.handle_event(@evh_last_event)
end

When('I call evh handle_event with a malformed event') do
  # Event with no player, no type set properly, no action
  @evh_last_event = Event.new(:SomeType, action: :some_action)
  # player is nil → malformed
  @evh_handler.handle_event(@evh_last_event)
end

When('I call evh handle_event with attached events') do
  player = EvhPlayerStub.new
  child  = Event.new(:EvhTestDispatch, player: player, action: :evh_test_action)
  parent = Event.new(:EvhTestDispatch, player: player, action: :evh_test_action)
  parent.attach_event(child)
  @evh_last_event = parent
  @evh_handler.handle_event(parent)
end

When('I call evh handle_event with nested attached events') do
  player     = EvhPlayerStub.new
  grandchild = Event.new(:EvhTestDispatch, player: player, action: :evh_test_action)
  child      = Event.new(:EvhTestDispatch, player: player, action: :evh_test_action)
  child.attach_event(grandchild)
  parent     = Event.new(:EvhTestDispatch, player: player, action: :evh_test_action)
  parent.attach_event(child)
  @evh_last_event = parent
  @evh_handler.handle_event(parent)
end

###############################################################################
# Then steps                                                                  #
###############################################################################
Then('the evh event queue should be empty') do
  assert(@evh_handler.event_queue.empty?,
    "Expected event queue to be empty, but it is not.")
end

Then('the evh handler should not be running') do
  running = @evh_handler.instance_variable_get(:@running)
  assert_equal(false, running, "Expected handler to not be running")
end

Then('the evh handler should be running') do
  running = @evh_handler.instance_variable_get(:@running)
  assert_equal(true, running, "Expected handler to be running")
end

Then('the evh handled events count should be {int}') do |count|
  assert_equal(count, @evh_handled_events.length,
    "Expected #{count} handled events, got #{@evh_handled_events.length}")
end

Then('the evh log should contain {string}') do |fragment|
  all_logs = $LOG.entries.map(&:to_s).join("\n")
  assert(all_logs.include?(fragment),
    "Expected log to contain #{fragment.inspect}, got: #{all_logs.inspect}")
end

Then('the evh dispatch count should be {int}') do |count|
  assert_equal(count, EvhTestDispatch.calls.length,
    "Expected #{count} dispatches, got #{EvhTestDispatch.calls.length}")
end

Then('the evh test module should have received the action') do
  assert(EvhTestDispatch.calls.length >= 1,
    "Expected EvhTestDispatch to have received at least 1 call, got #{EvhTestDispatch.calls.length}")
end

Then('the evh test module should have received {int} actions') do |count|
  assert_equal(count, EvhTestDispatch.calls.length,
    "Expected EvhTestDispatch to have received #{count} calls, got #{EvhTestDispatch.calls.length}")
end

Then('the evh last event at should equal the player goid') do
  assert_equal("evh_player_goid_42", @evh_last_event.at,
    "Expected event.at to be player goid, got #{@evh_last_event.at}")
end

Then('the evh last event object should equal the player goid') do
  assert_equal("evh_player_goid_42", @evh_last_event.object,
    "Expected event.object to be player goid, got #{@evh_last_event.object}")
end

Then('the evh last event target should equal the player goid') do
  assert_equal("evh_player_goid_42", @evh_last_event.target,
    "Expected event.target to be player goid, got #{@evh_last_event.target}")
end

Then('the evh manager should have received a future event') do
  assert($manager.future_events.length >= 1,
    "Expected manager to have received a future_event call, got #{$manager.future_events.length}")
end
