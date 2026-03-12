# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step-definitions for Aethyr::Experiments::CLI feature
#
# Exercises every branch in lib/aethyr/experiments/cli.rb by stubbing
# Runner so the heavy server/sandbox stack is never loaded.
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'stringio'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module – holds per-scenario state for CLI steps
# ---------------------------------------------------------------------------
module CLIWorld
  attr_accessor :cli_runner_called, :cli_runner_options,
                :cli_exit_status, :cli_stdout, :cli_stderr,
                :cli_original_runner
end
World(CLIWorld)

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

Given('the CLI module is loaded with a stubbed Runner') do
  # Reset per-scenario state
  self.cli_runner_called  = false
  self.cli_runner_options = nil
  self.cli_exit_status    = nil
  self.cli_stdout         = ""
  self.cli_stderr         = ""

  # Load cli.rb (and transitively runner.rb) first so all real code is in place.
  require 'aethyr/experiments/cli'

  # Save the real Runner so we can restore it later if needed.
  self.cli_original_runner = Aethyr::Experiments::Runner

  # Keep a reference to the World so the stub can record calls.
  world = self

  # (Re-)define a lightweight Runner that just records what it receives.
  runner_klass = Class.new do
    define_method(:initialize) do |options|
      @options = options
      world.cli_runner_options = options
    end

    define_method(:execute) do
      world.cli_runner_called = true
    end
  end

  # Replace Runner with our stub inside Aethyr::Experiments
  Aethyr::Experiments.send(:remove_const, :Runner)
  Aethyr::Experiments.const_set(:Runner, runner_klass)
end

When('I call CLI.start with arguments {string}') do |arg_string|
  argv = arg_string.strip.empty? ? [] : arg_string.strip.split(/\s+/)

  captured_out = StringIO.new
  captured_err = StringIO.new
  old_stdout = $stdout
  old_stderr = $stderr

  # Temporarily override Kernel#warn so it writes to our captured buffer.
  # This is necessary because in some Ruby + test-harness combinations,
  # warn bypasses the $stderr global variable.
  kernel_warn_owner = Kernel
  old_warn = kernel_warn_owner.instance_method(:warn)
  kernel_warn_owner.define_method(:warn) do |*msgs|
    msgs.each { |m| captured_err.puts(m) }
  end

  begin
    $stdout = captured_out
    $stderr = captured_err
    Aethyr::Experiments::CLI.start(argv)
  rescue SystemExit => e
    self.cli_exit_status = e.status
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
    # Restore Kernel#warn
    kernel_warn_owner.define_method(:warn, old_warn)
    self.cli_stdout = captured_out.string
    self.cli_stderr = captured_err.string
  end
end

Then('the CLI Runner should have been called') do
  assert(cli_runner_called, 'Expected Runner#execute to have been called')
end

Then('the CLI parsed option {string} should be {string}') do |key, expected|
  assert_not_nil(cli_runner_options,
                 'Expected Runner to have received options but it was never called')
  actual = cli_runner_options.send(key.to_sym)
  assert_equal(expected, actual.to_s,
               "Expected option #{key} to be #{expected.inspect}, got #{actual.inspect}")
end

Then('the CLI parsed option {string} should be true') do |key|
  assert_not_nil(cli_runner_options, 'Runner was never called')
  assert_equal(true, cli_runner_options.send(key.to_sym),
               "Expected option #{key} to be true")
end

Then('the CLI parsed option {string} should be false') do |key|
  assert_not_nil(cli_runner_options, 'Runner was never called')
  assert_equal(false, cli_runner_options.send(key.to_sym),
               "Expected option #{key} to be false")
end

Then('the CLI should have exited with status {int}') do |expected_status|
  assert_not_nil(cli_exit_status,
                 'Expected CLI to call exit but no SystemExit was raised')
  assert_equal(expected_status, cli_exit_status,
               "Expected exit status #{expected_status}, got #{cli_exit_status}")
end

Then('the CLI stdout should contain {string}') do |fragment|
  assert(cli_stdout.include?(fragment),
         "Expected stdout to contain #{fragment.inspect}, got:\n#{cli_stdout}")
end

Then('the CLI stderr should contain {string}') do |fragment|
  assert(cli_stderr.include?(fragment),
         "Expected stderr to contain #{fragment.inspect}, got:\n#{cli_stderr}")
end

# ---------------------------------------------------------------------------
# After hook – restore the real Runner constant so other features (runner.feature)
# operate on the Coverage-tracked original instead of the stub.
# ---------------------------------------------------------------------------
After do
  if cli_original_runner &&
     defined?(Aethyr::Experiments::Runner) &&
     Aethyr::Experiments::Runner != cli_original_runner
    Aethyr::Experiments.send(:remove_const, :Runner)
    Aethyr::Experiments.const_set(:Runner, cli_original_runner)
  end
  self.cli_original_runner = nil
end
