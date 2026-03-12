# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step definitions for Aethyr::Experiments::Runner feature
#
# Exercises lib/aethyr/experiments/runner.rb thoroughly, covering:
#   - require statements and module/class definition (lines 3-9, 25-26)
#   - def_delegators (line 29)
#   - initialize (lines 34-36)
#   - execute (lines 42-55)
#   - validate_script_path! (lines 62-66)
#   - boot_or_attach_server (lines 71-81)
#   - attach_to_running_server (lines 88-90)
#   - spawn_ephemeral_server (lines 95-116)
#   - bootstrap_player (lines 121-141)
#   - run_experiment_script (lines 146-151)
#   - graceful_shutdown (lines 156-163)
#   - log (lines 178-188)
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'tempfile'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module – holds all scenario state for Runner tests
# ---------------------------------------------------------------------------
module RunnerWorld
  attr_accessor :runner_instance,
                :runner_options,
                :runner_error,
                :runner_abort_message,
                :runner_exit_status,
                :runner_log_invoked,
                :runner_process_killed,
                :runner_spawned_pid,
                :runner_sandbox,
                :runner_script_evaluated,
                :runner_execute_completed,
                :runner_shutdown_called,
                :runner_shutdown_status,
                :runner_tmpfile
end
World(RunnerWorld)

# ---------------------------------------------------------------------------
# Test doubles for Runner tests
# ---------------------------------------------------------------------------
module RunnerTestDoubles
  # Minimal options struct that responds to script, player, attach?, verbose?
  class OptionsStruct
    attr_accessor :script, :player

    def initialize(script:, player:, attach:, verbose:)
      @script  = script
      @player  = player
      @attach  = attach
      @verbose = verbose
    end

    def attach?
      @attach
    end

    def verbose?
      @verbose
    end
  end

  # Fake Manager for Runner tests
  class FakeManager
    attr_reader :loaded_player, :created_player, :existing_players
    attr_accessor :game_objects

    def initialize(existing_players: [])
      @existing_players = existing_players
      @loaded_player = nil
      @created_player = nil
      @game_objects = {}
    end

    def player_exist?(name)
      @existing_players.include?(name)
    end

    def load_player(name, _pass)
      @loaded_player = FakePlayer.new(name)
      @loaded_player
    end

    def create_object(_klass, *_args, **attrs)
      name = attrs[:@name] || "unknown"
      @created_player = FakePlayer.new(name)
      @created_player
    end
  end

  # Fake Player
  class FakePlayer
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end

  # Fake Sandbox that tracks calls
  class FakeSandbox
    attr_reader :eval_called, :wait_called, :eval_content, :eval_file
    attr_reader :server, :player, :verbose

    def initialize(server: nil, player: nil, verbose: false)
      @server  = server
      @player  = player
      @verbose = verbose
      @eval_called = false
      @wait_called = false
    end

    def instance_eval(content, file, _line)
      @eval_called = true
      @eval_content = content
      @eval_file = file
    end

    def wait_until_idle
      @wait_called = true
    end
  end
end

# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------

Given('the Runner module is loaded') do
  require 'timeout'
  require 'forwardable'

  # Ensure Logger::Ultimate is available
  require 'aethyr/core/util/log' unless defined?(Logger::Ultimate)

  # Load runner.rb.  The CLI After hook now restores the original Runner
  # constant, so this `require` either loads it fresh (first time) or is a
  # no-op (already loaded under Coverage tracking).
  require 'aethyr/experiments/runner'

  assert(defined?(Aethyr::Experiments::Runner), "Expected Aethyr::Experiments::Runner to be defined")
end

Then('the class Aethyr::Experiments::Runner should be defined') do
  assert(defined?(Aethyr::Experiments::Runner), "Expected Aethyr::Experiments::Runner to be defined")
end

# ---------------------------------------------------------------------------
# Options struct construction
# ---------------------------------------------------------------------------
Given('a Runner options struct with script {string} and player {string} and attach {word} and verbose {word}') do |script, player, attach, verbose|
  self.runner_options = RunnerTestDoubles::OptionsStruct.new(
    script:  script,
    player:  player,
    attach:  attach == 'true',
    verbose: verbose == 'true'
  )
end

Given('a Runner options struct with a valid temp script') do
  self.runner_tmpfile = Tempfile.new(['runner_test', '.rb'])
  runner_tmpfile.write("# test script\n")
  runner_tmpfile.flush
  self.runner_options = RunnerTestDoubles::OptionsStruct.new(
    script:  runner_tmpfile.path,
    player:  'sandbox',
    attach:  false,
    verbose: false
  )
end

# ---------------------------------------------------------------------------
# Construction
# ---------------------------------------------------------------------------
When('I construct a Runner with those options') do
  self.runner_instance = Aethyr::Experiments::Runner.new(runner_options)
end

Then('the Runner should be an instance of Aethyr::Experiments::Runner') do
  assert_instance_of(Aethyr::Experiments::Runner, runner_instance)
end

# ---------------------------------------------------------------------------
# Delegators
# ---------------------------------------------------------------------------
Then('the Runner verbose? should be true') do
  assert_equal(true, runner_instance.send(:verbose?))
end

Then('the Runner attach? should be true') do
  assert_equal(true, runner_instance.send(:attach?))
end

# ---------------------------------------------------------------------------
# validate_script_path!
# ---------------------------------------------------------------------------
When('I call validate_script_path! on the Runner') do
  self.runner_error = nil
  begin
    runner_instance.send(:validate_script_path!)
  rescue SystemExit => e
    self.runner_error = e
  rescue => e
    self.runner_error = e
  end
end

Then('no error should have been raised by the Runner') do
  assert_nil(runner_error, "Expected no error but got: #{runner_error.inspect}")
end

When('I call validate_script_path! on the Runner expecting abort') do
  self.runner_abort_message = nil
  captured = nil
  runner_instance.define_singleton_method(:abort) do |msg = ""|
    captured = msg
    raise SystemExit.new(1), msg
  end

  begin
    runner_instance.send(:validate_script_path!)
  rescue SystemExit
    # expected
  end
  self.runner_abort_message = captured
end

Then('the Runner should have aborted with message containing {string}') do |expected|
  assert_not_nil(runner_abort_message, "Expected abort to have been called")
  assert(runner_abort_message.include?(expected),
         "Expected abort message to contain '#{expected}', got: '#{runner_abort_message}'")
end

# ---------------------------------------------------------------------------
# boot_or_attach_server – attach mode
# ---------------------------------------------------------------------------
Given('$manager is set to a fake manager for Runner tests') do
  @_runner_orig_manager = $manager
  $manager = RunnerTestDoubles::FakeManager.new
end

When('I call boot_or_attach_server on the Runner') do
  self.runner_error = nil
  # Stub log to avoid issues with $LOG
  runner_instance.define_singleton_method(:log) { |_msg| }
  begin
    runner_instance.send(:boot_or_attach_server)
  rescue => e
    self.runner_error = e
  end
end

Given('$manager is cleared for Runner tests') do
  @_runner_orig_manager = $manager
  $manager = nil
end

When('I call boot_or_attach_server on the Runner expecting abort') do
  self.runner_abort_message = nil
  captured = nil
  runner_instance.define_singleton_method(:abort) do |msg = ""|
    captured = msg
    raise SystemExit.new(1), msg
  end
  runner_instance.define_singleton_method(:log) { |_msg| }

  begin
    runner_instance.send(:boot_or_attach_server)
  rescue SystemExit
    # expected
  end
  self.runner_abort_message = captured
end

# ---------------------------------------------------------------------------
# boot_or_attach_server – non-attach mode (covers line 77)
# ---------------------------------------------------------------------------
When('I call boot_or_attach_server in non-attach mode on the Runner') do
  self.runner_error = nil
  runner_instance.define_singleton_method(:log) { |_msg| }
  # Stub spawn_ephemeral_server to be a no-op
  runner_instance.define_singleton_method(:spawn_ephemeral_server) { }
  # Set $manager so the log line at 80 works
  @_runner_orig_manager = $manager
  $manager = RunnerTestDoubles::FakeManager.new

  begin
    runner_instance.send(:boot_or_attach_server)
  rescue => e
    self.runner_error = e
  end
end

# ---------------------------------------------------------------------------
# spawn_ephemeral_server – executable launcher path
# ---------------------------------------------------------------------------
Given('spawn is stubbed to return a fake pid for Runner tests') do
  self.runner_spawned_pid = 99999
end

When('I call spawn_ephemeral_server on the Runner with executable launcher') do
  self.runner_error = nil
  fake_pid = runner_spawned_pid

  # Stub the require to avoid loading full aethyr
  runner_instance.define_singleton_method(:require) { |_lib| true }
  runner_instance.define_singleton_method(:log) { |_msg| }

  # Stub File.executable? and File.expand_path for the launcher
  original_file_executable = File.method(:executable?)

  # Stub spawn on the runner instance
  runner_instance.define_singleton_method(:spawn) { |*_args| fake_pid }

  # Stub File.executable? to return true for the launcher
  File.define_singleton_method(:executable?) do |path|
    if path.include?('bin/aethyr')
      true
    else
      original_file_executable.call(path)
    end
  end

  # Stub Timeout.timeout to just yield (since $manager is already set)
  original_timeout = Timeout.method(:timeout)
  Timeout.define_singleton_method(:timeout) do |_secs, &blk|
    blk.call
  end

  # Stub sleep
  runner_instance.define_singleton_method(:sleep) { |_t| }

  begin
    runner_instance.send(:spawn_ephemeral_server)
  rescue => e
    self.runner_error = e
  ensure
    File.define_singleton_method(:executable?) { |*a| original_file_executable.call(*a) }
    Timeout.define_singleton_method(:timeout) { |*a, &b| original_timeout.call(*a, &b) }
  end
end

Then('the Runner should have a spawned pid') do
  pid = runner_instance.instance_variable_get(:@spawned_pid)
  assert_not_nil(pid, "Expected @spawned_pid to be set")
  assert_equal(runner_spawned_pid, pid)
end

# ---------------------------------------------------------------------------
# spawn_ephemeral_server – non-executable fallback
# ---------------------------------------------------------------------------
When('I call spawn_ephemeral_server on the Runner with non-executable launcher') do
  self.runner_error = nil

  # Track whether Manager was already defined before this step
  manager_was_defined = defined?(::Manager)

  # Stub require to avoid loading full aethyr
  runner_instance.define_singleton_method(:require) { |lib|
    if lib == "aethyr/core/components/manager"
      # Define a stub Manager at top level if not defined
      unless defined?(::Manager)
        Object.const_set(:Manager, Class.new {
          def initialize; end
        })
      end
      true
    else
      true
    end
  }
  runner_instance.define_singleton_method(:log) { |_msg| }
  runner_instance.define_singleton_method(:warn) { |_msg| }

  # Stub File.executable? to return false
  original_file_executable = File.method(:executable?)
  File.define_singleton_method(:executable?) do |path|
    if path.include?('bin/aethyr')
      false
    else
      original_file_executable.call(path)
    end
  end

  # Clear $manager to trigger the ||= assignment
  @_runner_orig_manager = $manager
  $manager = nil

  begin
    runner_instance.send(:spawn_ephemeral_server)
  rescue => e
    self.runner_error = e
  ensure
    File.define_singleton_method(:executable?) { |*a| original_file_executable.call(*a) }
    # Clean up the stub Manager to avoid superclass mismatch when the real
    # Manager (< Publisher) is loaded later by other test files.
    if !manager_was_defined && defined?(::Manager)
      Object.send(:remove_const, :Manager)
    end
  end
end

Then('$manager should be set for Runner tests') do
  assert_not_nil($manager, "Expected $manager to be set after fallback boot")
end

# ---------------------------------------------------------------------------
# spawn_ephemeral_server – timeout
# ---------------------------------------------------------------------------
When('I call spawn_ephemeral_server on the Runner expecting timeout abort') do
  self.runner_abort_message = nil

  # Stub require
  runner_instance.define_singleton_method(:require) { |_lib| true }
  runner_instance.define_singleton_method(:log) { |_msg| }

  captured = nil
  runner_instance.define_singleton_method(:abort) do |msg = ""|
    captured = msg
    raise SystemExit.new(1), msg
  end

  # Stub File.executable? to return true
  original_file_executable = File.method(:executable?)
  File.define_singleton_method(:executable?) do |path|
    if path.include?('bin/aethyr')
      true
    else
      original_file_executable.call(path)
    end
  end

  # Stub spawn
  runner_instance.define_singleton_method(:spawn) { |*_args| 12345 }

  # Stub Timeout.timeout to raise Timeout::Error
  original_timeout = Timeout.method(:timeout)
  Timeout.define_singleton_method(:timeout) do |_secs, &_blk|
    raise Timeout::Error, "execution expired"
  end

  begin
    runner_instance.send(:spawn_ephemeral_server)
  rescue SystemExit
    # expected
  end
  self.runner_abort_message = captured

  File.define_singleton_method(:executable?) { |*a| original_file_executable.call(*a) }
  Timeout.define_singleton_method(:timeout) { |*a, &b| original_timeout.call(*a, &b) }
end

# ---------------------------------------------------------------------------
# bootstrap_player – existing player
# ---------------------------------------------------------------------------
Given('$manager is set to a fake manager that has the player for Runner tests') do
  @_runner_orig_manager = $manager
  $manager = RunnerTestDoubles::FakeManager.new(existing_players: [runner_options.player])
end

When('I call bootstrap_player on the Runner') do
  self.runner_error = nil
  runner_instance.define_singleton_method(:log) { |_msg| }

  # Ensure Aethyr::Core::Objects::Player is defined
  unless defined?(Aethyr::Core::Objects::Player)
    module Aethyr; module Core; module Objects
      class Player; end
    end; end; end
  end

  # Stub require to not load the real player
  runner_instance.define_singleton_method(:require) { |_lib| true }

  # Stub Sandbox.new to return a FakeSandbox instead of the real one
  # (the real Sandbox tries to start Concurrent::TimerTask)
  @_runner_orig_sandbox_new = Aethyr::Experiments::Sandbox.method(:new)
  Aethyr::Experiments::Sandbox.define_singleton_method(:new) do |**kwargs|
    RunnerTestDoubles::FakeSandbox.new(**kwargs)
  end

  begin
    runner_instance.send(:bootstrap_player)
  rescue => e
    self.runner_error = e
  end
end

Then('the Runner should have a sandbox with the loaded player') do
  sandbox = runner_instance.instance_variable_get(:@sandbox)
  assert_not_nil(sandbox, "Expected @sandbox to be set")
  player = runner_instance.instance_variable_get(:@player)
  assert_not_nil(player, "Expected @player to be set")
  assert_equal(runner_options.player, player.name)
  # Verify it was loaded (not created)
  assert_not_nil($manager.loaded_player, "Expected player to have been loaded")
end

# ---------------------------------------------------------------------------
# bootstrap_player – new player
# ---------------------------------------------------------------------------
Given('$manager is set to a fake manager without the player for Runner tests') do
  @_runner_orig_manager = $manager
  $manager = RunnerTestDoubles::FakeManager.new(existing_players: [])
end

Then('the Runner should have a sandbox with the created player') do
  sandbox = runner_instance.instance_variable_get(:@sandbox)
  assert_not_nil(sandbox, "Expected @sandbox to be set")
  player = runner_instance.instance_variable_get(:@player)
  assert_not_nil(player, "Expected @player to be set")
  # Verify it was created (not loaded)
  assert_not_nil($manager.created_player, "Expected player to have been created")
end

# ---------------------------------------------------------------------------
# run_experiment_script
# ---------------------------------------------------------------------------
Given('a Runner with a fake sandbox and valid script') do
  self.runner_tmpfile = Tempfile.new(['runner_test_script', '.rb'])
  runner_tmpfile.write("# experiment script\n")
  runner_tmpfile.flush

  self.runner_options = RunnerTestDoubles::OptionsStruct.new(
    script:  runner_tmpfile.path,
    player:  'sandbox',
    attach:  false,
    verbose: false
  )
  self.runner_instance = Aethyr::Experiments::Runner.new(runner_options)
  runner_instance.define_singleton_method(:log) { |_msg| }

  fake_sandbox = RunnerTestDoubles::FakeSandbox.new
  runner_instance.instance_variable_set(:@sandbox, fake_sandbox)
  self.runner_sandbox = fake_sandbox
end

When('I call run_experiment_script on the Runner') do
  self.runner_error = nil
  begin
    runner_instance.send(:run_experiment_script)
  rescue => e
    self.runner_error = e
  end
end

Then('the Runner sandbox should have evaluated the script') do
  assert(runner_sandbox.eval_called, "Expected sandbox.instance_eval to have been called")
  assert(runner_sandbox.wait_called, "Expected sandbox.wait_until_idle to have been called")
end

# ---------------------------------------------------------------------------
# graceful_shutdown – no spawned pid (default exit status 0)
# ---------------------------------------------------------------------------
When('I call graceful_shutdown on the Runner with exit stubbed') do
  self.runner_exit_status = nil
  self.runner_process_killed = false
  captured_status = nil
  killed = false

  runner_instance.define_singleton_method(:exit) do |status = 0|
    captured_status = status
  end
  runner_instance.define_singleton_method(:log) { |_msg| }

  # If there's a spawned pid, stub Process.kill and Process.wait
  if runner_instance.instance_variable_get(:@spawned_pid)
    original_kill = Process.method(:kill)
    original_wait = Process.method(:wait)
    Process.define_singleton_method(:kill) { |*_a| killed = true }
    Process.define_singleton_method(:wait) { |*_a| }

    runner_instance.send(:graceful_shutdown)

    Process.define_singleton_method(:kill) { |*a| original_kill.call(*a) }
    Process.define_singleton_method(:wait) { |*a| original_wait.call(*a) }
  else
    runner_instance.send(:graceful_shutdown)
  end

  self.runner_exit_status = captured_status
  self.runner_process_killed = killed
end

Then('the Runner should have exited with status {int}') do |expected|
  assert_equal(expected, runner_exit_status)
end

# ---------------------------------------------------------------------------
# graceful_shutdown – with spawned pid
# ---------------------------------------------------------------------------
Given('the Runner has a spawned pid') do
  runner_instance.instance_variable_set(:@spawned_pid, 99999)
end

Then('the Runner should have killed the spawned process') do
  assert(runner_process_killed, "Expected the spawned process to have been killed")
end

# ---------------------------------------------------------------------------
# graceful_shutdown – non-zero exit
# ---------------------------------------------------------------------------
When('I call graceful_shutdown on the Runner with exit stubbed and status {int}') do |status|
  self.runner_exit_status = nil
  captured_status = nil
  runner_instance.define_singleton_method(:exit) do |st = 0|
    captured_status = st
  end
  runner_instance.define_singleton_method(:log) { |_msg| }
  runner_instance.send(:graceful_shutdown, status)
  self.runner_exit_status = captured_status
end

# ---------------------------------------------------------------------------
# log
# ---------------------------------------------------------------------------
When('I call log on the Runner with message {string}') do |msg|
  self.runner_log_invoked = false
  invoked = false

  # We need to intercept the super call. We do this by stubbing $LOG.
  original_log = $LOG
  fake_log = Object.new
  fake_log.define_singleton_method(:add) { |*_args| invoked = true }
  fake_log.define_singleton_method(:method) { |name|
    if name == :add
      m = fake_log.public_method(:add)
      # Make parameters return dump_log keyword
      m.define_singleton_method(:parameters) { [[:req, :log_level], [:opt, :msg], [:opt, :progname], [:key, :dump_log]] }
      m
    else
      super(name)
    end
  }
  $LOG = fake_log

  begin
    runner_instance.send(:log, msg)
  rescue => _e
    # In case super raises
  end
  self.runner_log_invoked = invoked

  $LOG = original_log
end

Then('the Runner log should have been invoked') do
  assert(runner_log_invoked, "Expected log to have been invoked via super")
end

Then('the Runner log should not have been invoked') do
  assert(!runner_log_invoked, "Expected log NOT to have been invoked")
end

# ---------------------------------------------------------------------------
# execute – happy path
# ---------------------------------------------------------------------------
Given('a fully stubbed Runner for the happy path') do
  self.runner_tmpfile = Tempfile.new(['runner_exec_test', '.rb'])
  runner_tmpfile.write("# happy path\n")
  runner_tmpfile.flush

  self.runner_options = RunnerTestDoubles::OptionsStruct.new(
    script:  runner_tmpfile.path,
    player:  'sandbox',
    attach:  false,
    verbose: false
  )
  self.runner_instance = Aethyr::Experiments::Runner.new(runner_options)

  # Stub all the private methods called by execute
  runner_instance.define_singleton_method(:validate_script_path!) { }
  runner_instance.define_singleton_method(:boot_or_attach_server) { }
  runner_instance.define_singleton_method(:bootstrap_player) { }
  runner_instance.define_singleton_method(:run_experiment_script) { }
  runner_instance.define_singleton_method(:graceful_shutdown) { |status = 0| }
  self.runner_execute_completed = false
end

When('I call execute on the Runner') do
  begin
    runner_instance.execute
    self.runner_execute_completed = true
  rescue SystemExit
    self.runner_execute_completed = true
  rescue => e
    self.runner_error = e
    self.runner_execute_completed = true
  end
end

Then('the Runner should have completed execution successfully') do
  assert(runner_execute_completed, "Expected execute to complete")
  assert_nil(runner_error, "Expected no error during execute, got: #{runner_error.inspect}")
end

# ---------------------------------------------------------------------------
# execute – Interrupt rescue
# ---------------------------------------------------------------------------
Given('a fully stubbed Runner that raises Interrupt during validation') do
  self.runner_options = RunnerTestDoubles::OptionsStruct.new(
    script:  'test.rb',
    player:  'sandbox',
    attach:  false,
    verbose: false
  )
  self.runner_instance = Aethyr::Experiments::Runner.new(runner_options)
  self.runner_shutdown_called = false
  self.runner_shutdown_status = nil

  shutdown_tracker = self
  runner_instance.define_singleton_method(:validate_script_path!) {
    raise Interrupt, "test interrupt"
  }
  runner_instance.define_singleton_method(:warn) { |_msg| }
  runner_instance.define_singleton_method(:graceful_shutdown) { |status = 0|
    shutdown_tracker.runner_shutdown_called = true
    shutdown_tracker.runner_shutdown_status = status
  }
end

Then('the Runner should have shut down after interrupt') do
  assert(runner_shutdown_called, "Expected graceful_shutdown to have been called after Interrupt")
  # Interrupt path calls graceful_shutdown with no arg (default 0)
  assert_equal(0, runner_shutdown_status)
end

# ---------------------------------------------------------------------------
# execute – StandardError rescue
# ---------------------------------------------------------------------------
Given('a fully stubbed Runner that raises StandardError during validation') do
  self.runner_options = RunnerTestDoubles::OptionsStruct.new(
    script:  'test.rb',
    player:  'sandbox',
    attach:  false,
    verbose: false
  )
  self.runner_instance = Aethyr::Experiments::Runner.new(runner_options)
  self.runner_shutdown_called = false
  self.runner_shutdown_status = nil

  shutdown_tracker = self
  runner_instance.define_singleton_method(:validate_script_path!) {
    raise StandardError, "test standard error"
  }
  runner_instance.define_singleton_method(:warn) { |*_args| }
  runner_instance.define_singleton_method(:graceful_shutdown) { |status = 0|
    shutdown_tracker.runner_shutdown_called = true
    shutdown_tracker.runner_shutdown_status = status
  }
end

Then('the Runner should have shut down after standard error') do
  assert(runner_shutdown_called, "Expected graceful_shutdown to have been called after StandardError")
  assert_equal(1, runner_shutdown_status)
end

# ---------------------------------------------------------------------------
# After hook – restore globals
# ---------------------------------------------------------------------------
After('@unit') do
  # Restore $manager
  if defined?(@_runner_orig_manager) && !@_runner_orig_manager.nil?
    $manager = @_runner_orig_manager
    @_runner_orig_manager = nil
  end

  # Restore Sandbox.new
  if defined?(@_runner_orig_sandbox_new) && @_runner_orig_sandbox_new
    orig_sn = @_runner_orig_sandbox_new
    Aethyr::Experiments::Sandbox.define_singleton_method(:new) { |**kw| orig_sn.call(**kw) }
    @_runner_orig_sandbox_new = nil
  end

  # Clean up temp files
  if defined?(@runner_tmpfile) && @runner_tmpfile
    @runner_tmpfile.close rescue nil
    @runner_tmpfile.unlink rescue nil
    @runner_tmpfile = nil
  end
end
