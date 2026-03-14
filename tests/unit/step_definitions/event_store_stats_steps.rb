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
require 'json'

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
# Coverage-snapshot merging module
#
# Extracted into a module so the logic is independently testable. The
# SimpleCov adapter hook (below) delegates to these methods.
# ---------------------------------------------------------------------------
module EventStoreStatsCovMerger
  module_function

  # Merge an array of coverage snapshots (each an Array<Integer|nil>) into a
  # single merged array using max-per-line semantics.
  #
  # Returns nil when +snapshots+ is empty.
  def merge_snapshots(snapshots)
    return nil if snapshots.empty?

    merged = nil
    snapshots.each do |snap|
      if merged.nil?
        merged = snap.dup
      else
        snap.each_with_index do |count, idx|
          next if count.nil? || merged[idx].nil?
          merged[idx] = [merged[idx], count].max
        end
      end
    end
    merged
  end

  # Inject +merged+ coverage data into the raw +coverage_result+ hash
  # (keyed by source-file path) so SimpleCov sees the combined result.
  def inject_merged(merged, coverage_result)
    return unless merged

    key = coverage_result.keys.find { |k| k.include?('event_store_stats.rb') && !k.include?('step') }
    return unless key

    val = coverage_result[key]
    if val.is_a?(Hash) && val.key?(:lines)
      val[:lines] = merged
    elsif val.is_a?(Array)
      coverage_result[key] = merged
    else
      coverage_result[key] = { lines: merged }
    end
  end

  # Apply snapshot merging to a coverage result hash.
  # This is the top-level entry point used by the SimpleCov adapter hook
  # and also callable directly for testing.
  def apply(snapshots, coverage_result)
    merged = merge_snapshots(snapshots)
    inject_merged(merged, coverage_result)
  end

  # Install the SimpleCov adapter monkey-patch (only if SimpleCov is loaded).
  # Returns true if the hook was installed, false otherwise.
  def install_simplecov_hook!
    return false unless defined?(SimpleCov) && defined?(SimpleCov::ResultAdapter)

    original_call = SimpleCov::ResultAdapter.method(:call)

    SimpleCov::ResultAdapter.define_singleton_method(:call) do |coverage_result|
      EventStoreStatsCovMerger.apply(EVENT_STORE_STATS_COV_SNAPSHOTS, coverage_result)
      original_call.call(coverage_result)
    end
    true
  end
end

# Install the SimpleCov hook at load time (no-op when SimpleCov is absent).
EventStoreStatsCovMerger.install_simplecov_hook!

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
# Steps -- ServerConfig creation branch
# ---------------------------------------------------------------------------

Given('ServerConfig is temporarily removed') do
  # Stash the real ServerConfig so the `unless defined?` branch executes.
  @_original_server_config = ServerConfig
  Object.send(:remove_const, :ServerConfig)
end

# ---------------------------------------------------------------------------
# Steps -- Coverage-snapshot merging logic
# ---------------------------------------------------------------------------

Given('an empty set of coverage snapshots') do
  @_cov_snapshots = []
end

Given('a single coverage snapshot {string}') do |json|
  @_cov_snapshots = [JSON.parse(json)]
end

Given('coverage snapshots {string} and {string}') do |json_a, json_b|
  @_cov_snapshots = [JSON.parse(json_a), JSON.parse(json_b)]
end

When('I merge the coverage snapshots') do
  @_merged_result = EventStoreStatsCovMerger.merge_snapshots(@_cov_snapshots)
end

Then('the merged snapshot should be nil') do
  assert_nil(@_merged_result, 'Expected merged result to be nil')
end

Then('the merged snapshot should be {string}') do |json|
  expected = JSON.parse(json)
  assert_equal(expected, @_merged_result)
end

Given('a coverage result hash with a Hash lines entry for {string}') do |file_key|
  @_cov_result = { file_key => { lines: [0, 0, 0] } }
end

Given('a coverage result hash with an Array entry for {string}') do |file_key|
  @_cov_result = { file_key => [0, 0, 0] }
end

Given('a coverage result hash with a String entry for {string}') do |file_key|
  @_cov_result = { file_key => 'opaque' }
end

When('I inject merged data {string} into the coverage result') do |json|
  merged = JSON.parse(json)
  EventStoreStatsCovMerger.inject_merged(merged, @_cov_result)
end

When('I inject nil merged data into the coverage result') do
  EventStoreStatsCovMerger.inject_merged(nil, @_cov_result)
end

Then('the coverage result for {string} should have lines {string}') do |file_key, json|
  expected = JSON.parse(json)
  val = @_cov_result[file_key]
  actual_lines = val.is_a?(Hash) ? val[:lines] : val
  assert_equal(expected, actual_lines)
end

Then('the coverage result for {string} should be unchanged') do |file_key|
  # If the key held a non-Hash / non-Array sentinel, it should still be there.
  assert(@_cov_result.key?(file_key), "Expected key #{file_key} to still exist")
end

# ---------------------------------------------------------------------------
# Steps -- SimpleCov adapter hook
# ---------------------------------------------------------------------------

When('I apply coverage merging for snapshots {string} to result with Hash entry for {string}') do |json, file_key|
  snaps = JSON.parse(json)
  @_cov_result = { file_key => { lines: [0, 0, 0] } }
  EventStoreStatsCovMerger.apply(snaps, @_cov_result)
end

Given('SimpleCov is temporarily hidden') do
  if defined?(SimpleCov)
    @_real_simplecov = SimpleCov
    Object.send(:remove_const, :SimpleCov)
  end
end

When('I install the SimpleCov hook') do
  @_hook_installed = EventStoreStatsCovMerger.install_simplecov_hook!
end

Then('the hook installation should return false') do
  assert_equal(false, @_hook_installed)
end

Given('a mock SimpleCov ResultAdapter is defined') do
  # Create a minimal SimpleCov::ResultAdapter mock if SimpleCov is not loaded.
  unless defined?(SimpleCov)
    @_simplecov_was_undefined = true
    simplecov_mod = Module.new
    Object.const_set(:SimpleCov, simplecov_mod)
    adapter_class = Class.new do
      def self.call(coverage_result)
        coverage_result
      end
    end
    SimpleCov.const_set(:ResultAdapter, adapter_class)
  end
end

When('I install the SimpleCov hook with the mock adapter') do
  @_hook_installed = EventStoreStatsCovMerger.install_simplecov_hook!
end

When('I invoke the hooked adapter with snapshots {string} and Hash entry for {string}') do |json, file_key|
  snaps = JSON.parse(json)
  # Temporarily replace EVENT_STORE_STATS_COV_SNAPSHOTS contents
  @_saved_snapshots = EVENT_STORE_STATS_COV_SNAPSHOTS.dup
  EVENT_STORE_STATS_COV_SNAPSHOTS.clear
  snaps.each { |s| EVENT_STORE_STATS_COV_SNAPSHOTS << s }
  @_cov_result = { file_key => { lines: [0, 0, 0] } }
  SimpleCov::ResultAdapter.call(@_cov_result)
end

Then('the hook installation should return true') do
  assert_equal(true, @_hook_installed)
end

# ---------------------------------------------------------------------------
# Cleanup -- restore $manager and $LOADED_FEATURES after every scenario
# ---------------------------------------------------------------------------
After do
  $manager = nil
  if defined?(@_stats_fake_feature) && @_stats_fake_feature
    $LOADED_FEATURES.delete(@_stats_fake_feature)
  end
  # Restore original ServerConfig if it was stashed.
  if defined?(@_original_server_config) && @_original_server_config
    Object.send(:remove_const, :ServerConfig) if defined?(ServerConfig)
    Object.const_set(:ServerConfig, @_original_server_config)
    @_original_server_config = nil
  end
  # Remove mock SimpleCov if we created it.
  if defined?(@_simplecov_was_undefined) && @_simplecov_was_undefined
    Object.send(:remove_const, :SimpleCov) if defined?(SimpleCov)
    @_simplecov_was_undefined = nil
  end
  # Restore real SimpleCov if it was hidden.
  if defined?(@_real_simplecov) && @_real_simplecov
    Object.send(:remove_const, :SimpleCov) if defined?(SimpleCov)
    Object.const_set(:SimpleCov, @_real_simplecov)
    @_real_simplecov = nil
  end
  # Restore saved snapshots if any.
  if defined?(@_saved_snapshots) && @_saved_snapshots
    EVENT_STORE_STATS_COV_SNAPSHOTS.clear
    @_saved_snapshots.each { |s| EVENT_STORE_STATS_COV_SNAPSHOTS << s }
    @_saved_snapshots = nil
  end
end
