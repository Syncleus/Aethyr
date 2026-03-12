# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step-definitions for the migrate_to_event_store script feature
#
# Exercises every executable line in lib/aethyr/migrate_to_event_store.rb by:
#   - stubbing `require 'aethyr'` via $LOADED_FEATURES
#   - setting up $manager with mock storage returning success / failure / nil
#   - capturing $stdout to verify the script's informational messages
#
# Ruby's Coverage API resets line counters each time a file is `load`-ed,
# so each individual `load` only records lines for one branch.  We work
# around this by capturing `Coverage.peek_result` after every load and
# patching SimpleCov's result-adapter to inject the merged per-line maxima,
# ensuring that the coverage report reflects all three code-paths.
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'stringio'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module to hold scenario state for migration steps
# ---------------------------------------------------------------------------
module MigrationWorld
  attr_accessor :migration_output
end
World(MigrationWorld)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
MIGRATION_SCRIPT_PATH = File.expand_path(
  '../../../../lib/aethyr/migrate_to_event_store.rb', __FILE__
).freeze

# ---------------------------------------------------------------------------
# Coverage accumulation
# ---------------------------------------------------------------------------
# Collect per-line hit counts after each `load` so we can merge them later.
$__migration_coverage_snapshots = []

def capture_migration_coverage_snapshot
  return unless defined?(Coverage) && Coverage.running?

  peek = Coverage.peek_result[MIGRATION_SCRIPT_PATH]
  return unless peek

  lines = peek.is_a?(Hash) ? (peek[:lines] || peek["lines"]) : peek
  $__migration_coverage_snapshots << lines.dup if lines
end

def load_migration_script_with_output
  lib_dir = File.expand_path('../../../../lib', __FILE__)
  fake_feature = File.join(lib_dir, 'aethyr.rb')
  $LOADED_FEATURES << fake_feature unless $LOADED_FEATURES.include?(fake_feature)

  captured = StringIO.new
  original_stdout = $stdout
  begin
    $stdout = captured
    load MIGRATION_SCRIPT_PATH
  ensure
    $stdout = original_stdout
    $LOADED_FEATURES.delete(fake_feature)
  end

  capture_migration_coverage_snapshot
  self.migration_output = captured.string
end

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

Given('the migration environment is prepared') do
  # No-op; actual stubbing handled inside load_migration_script_with_output.
end

When('I run the migration script with a successful storage migration') do
  storage = Object.new
  storage.define_singleton_method(:migrate_to_event_store) { true }
  mgr = Object.new
  mgr.define_singleton_method(:storage) { storage }
  $manager = mgr
  load_migration_script_with_output
end

When('I run the migration script with a failed storage migration') do
  storage = Object.new
  storage.define_singleton_method(:migrate_to_event_store) { nil }
  mgr = Object.new
  mgr.define_singleton_method(:storage) { storage }
  $manager = mgr
  load_migration_script_with_output
end

When('I run the migration script with no manager available') do
  $manager = nil
  load_migration_script_with_output
end

Then('the migration output should include {string}') do |expected|
  assert(migration_output.include?(expected),
         "Expected output to include #{expected.inspect} but got:\n#{migration_output}")
end

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
After do
  $manager = nil
end

# ---------------------------------------------------------------------------
# Patch SimpleCov's result-adapter to inject merged coverage for the
# migration script.  This runs after Coverage.result is called but before
# SimpleCov builds its SourceFile objects, so all formatters benefit.
# ---------------------------------------------------------------------------
if defined?(SimpleCov)
  class << SimpleCov
    alias_method :__original_adapt_coverage_result__, :adapt_coverage_result

    private

    def adapt_coverage_result
      __original_adapt_coverage_result__

      snapshots = $__migration_coverage_snapshots
      return if snapshots.nil? || snapshots.empty?

      # Merge: for each line, take the maximum hit-count across all loads.
      merged = snapshots.first.each_with_index.map do |_, idx|
        values = snapshots.map { |s| s[idx] }
        values.all?(&:nil?) ? nil : values.compact.max
      end

      # Inject the merged line data into SimpleCov's raw result hash.
      if @result.is_a?(Hash) && @result.key?(MIGRATION_SCRIPT_PATH)
        entry = @result[MIGRATION_SCRIPT_PATH]
        if entry.is_a?(Hash) && entry.key?(:lines)
          entry[:lines] = merged
        elsif entry.is_a?(Array)
          @result[MIGRATION_SCRIPT_PATH] = merged
        end
      end
    end
  end
end
