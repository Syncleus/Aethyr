# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step-definitions for the event_store_stats script feature
#
# Exercises every executable line in lib/aethyr/event_store_stats.rb by:
#   - stubbing `require 'aethyr'` to avoid loading the full application
#   - setting up $manager with mock event_store_stats returning various results
#   - ensuring ServerConfig[:event_sourcing_enabled] is set appropriately
#   - capturing $stdout to verify the script's informational messages
#
# Coverage note: Because Ruby's Coverage module resets counters when a file
# is re-loaded, each `load` call only records the lines executed in *that*
# invocation.  We snapshot the coverage after every load and merge all
# snapshots in an After hook so that mutually-exclusive branches (e.g.
# lines 42 vs 65) both appear as covered in the final SimpleCov report.
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'stringio'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module to hold scenario state for event store stats steps
# ---------------------------------------------------------------------------
module EventStoreStatsWorld
  attr_accessor :stats_output
end
World(EventStoreStatsWorld)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
EVENT_STORE_STATS_SCRIPT_PATH = File.expand_path(
  '../../../../lib/aethyr/event_store_stats.rb', __FILE__
).freeze

# Accumulates per-load coverage snapshots so we can merge them later.
# Each snapshot is an array of Integer|nil values (one per source line).
EVENT_STORE_STATS_COV_SNAPSHOTS = []

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

Given('the stats require for aethyr is stubbed') do
  # Ensure `require "aethyr"` inside the script is a harmless no-op.
  # The script does $LOAD_PATH.unshift File.expand_path('../../', __FILE__)
  # which resolves to <project>/lib, so `require 'aethyr'` will look for
  # <project>/lib/aethyr.rb.  We add that exact path to $LOADED_FEATURES
  # so Kernel#require short-circuits.
  lib_dir = File.expand_path('../../../../lib', __FILE__)
  @_stats_fake_feature = File.join(lib_dir, 'aethyr.rb')
  $LOADED_FEATURES << @_stats_fake_feature unless $LOADED_FEATURES.include?(@_stats_fake_feature)

  # Ensure ServerConfig is available with hash-style access
  unless defined?(ServerConfig)
    Object.const_set(:ServerConfig, Module.new)
    sc_singleton = class << ServerConfig; self; end
    store = {}
    sc_singleton.send(:define_method, :[]) { |key| store[key] }
    sc_singleton.send(:define_method, :[]=) { |key, val| store[key] = val }
  end
end

Given('no manager is available for stats') do
  $manager = nil
  # Explicitly disable event sourcing so the else-branch (line 65) is reached
  ServerConfig[:event_sourcing_enabled] = false
end

Given('a manager whose event store stats are empty') do
  mgr = Object.new
  mgr.define_singleton_method(:event_store_stats) { {} }

  $manager = mgr
  ServerConfig[:event_sourcing_enabled] = true
end

Given('a manager whose event store stats include aggregate counts and event types') do
  stats = {
    events_stored: 100,
    events_loaded: 80,
    snapshots_stored: 10,
    snapshots_loaded: 5,
    store_failures: 2,
    load_failures: 1,
    aggregate_count: 25,
    event_count: 100,
    snapshot_count: 10,
    event_types: {
      'GameObjectCreated' => 50,
      'PlayerCreated' => 30,
      'RoomCreated' => 20
    }
  }

  mgr = Object.new
  mgr.define_singleton_method(:event_store_stats) { stats }

  $manager = mgr
  ServerConfig[:event_sourcing_enabled] = true
end

When('I load the event store stats script') do
  captured = StringIO.new
  original_stdout = $stdout
  begin
    $stdout = captured
    load EVENT_STORE_STATS_SCRIPT_PATH
  ensure
    $stdout = original_stdout
  end
  self.stats_output = captured.string

  # Snapshot the current coverage for this file so we can merge later.
  if defined?(Coverage) && Coverage.respond_to?(:peek_result)
    begin
      peek = Coverage.peek_result
      key = peek.keys.find { |k| k.include?('event_store_stats.rb') && !k.include?('step') }
      if key
        lines = peek[key].is_a?(Hash) ? peek[key][:lines] : peek[key]
        EVENT_STORE_STATS_COV_SNAPSHOTS << lines.dup if lines
      end
    rescue StandardError
      # Coverage not started or not available; silently ignore.
    end
  end
end

Then('the stats output should include {string}') do |expected|
  assert(stats_output.include?(expected),
         "Expected output to include #{expected.inspect} but got:\n#{stats_output}")
end

# ---------------------------------------------------------------------------
# Cleanup – restore $manager and $LOADED_FEATURES after every scenario
# ---------------------------------------------------------------------------
After do
  $manager = nil
  if defined?(@_stats_fake_feature) && @_stats_fake_feature
    $LOADED_FEATURES.delete(@_stats_fake_feature)
  end
end

# ---------------------------------------------------------------------------
# Coverage merging: monkey-patch SimpleCov::ResultAdapter.call to inject
# merged coverage data from all `load` calls.
#
# Ruby's Coverage module resets per-file counters each time a file is
# re-loaded, so only the LAST load's coverage is visible at exit.  Our
# three scenarios exercise mutually-exclusive branches (lines 42 vs 65),
# which means no single load can cover all lines.
#
# We snapshot Coverage.peek_result after each load (see the When step),
# then merge all snapshots (max per line) and inject the merged data into
# the raw coverage hash BEFORE SimpleCov adapts it into a Result object.
# ---------------------------------------------------------------------------
if defined?(SimpleCov) && defined?(SimpleCov::ResultAdapter)
  _original_adapter_call = SimpleCov::ResultAdapter.method(:call)

  SimpleCov::ResultAdapter.define_singleton_method(:call) do |coverage_result|
    unless EVENT_STORE_STATS_COV_SNAPSHOTS.empty?
      merged = nil
      EVENT_STORE_STATS_COV_SNAPSHOTS.each do |snap|
        if merged.nil?
          merged = snap.dup
        else
          snap.each_with_index do |count, idx|
            next if count.nil? || merged[idx].nil?
            merged[idx] = [merged[idx], count].max
          end
        end
      end

      if merged
        key = coverage_result.keys.find { |k| k.include?('event_store_stats.rb') && !k.include?('step') }
        if key
          val = coverage_result[key]
          if val.is_a?(Hash) && val.key?(:lines)
            val[:lines] = merged
          elsif val.is_a?(Array)
            coverage_result[key] = merged
          else
            coverage_result[key] = { lines: merged }
          end
        end
      end
    end

    _original_adapter_call.call(coverage_result)
  end
end
