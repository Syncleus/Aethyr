# frozen_string_literal: true

###############################################################################
# Step definitions for Aethyr::Experiments::Sandbox feature.                   #
###############################################################################
require 'test/unit/assertions'

World(Test::Unit::Assertions)

###############################################################################
# Fake Concurrent::TimerTask – replaces the real one so no background threads  #
# are spawned during testing.                                                  #
###############################################################################
module SandboxTestSupport
  class FakeTimerTask
    attr_reader :block, :options

    def initialize(**options, &block)
      @options = options
      @block = block
    end

    def execute
      # no-op: do not start background threads in tests
    end

    # Test helper: invoke the captured block directly.
    def execute_block
      @block.call if @block
    end
  end

  # Swap Concurrent::TimerTask at file-load time (before any scenarios run)
  # so that any `require 'aethyr/experiments/sandbox'` from other step
  # definitions (e.g. runner_steps.rb) will use our fake.
  require 'concurrent'
  unless Concurrent::TimerTask == FakeTimerTask
    unless const_defined?(:OriginalTimerTask)
      const_set(:OriginalTimerTask, Concurrent::TimerTask)
    end
    Concurrent.send(:remove_const, :TimerTask)
    Concurrent.const_set(:TimerTask, FakeTimerTask)
  end
end

###############################################################################
# Mock objects                                                                 #
###############################################################################
module SandboxWorld
  # Mock player with alert tracking
  class MockPlayer
    attr_reader :alerts

    def initialize
      @alerts = []
    end

    def alert(msg)
      @alerts << msg
    end

    def alerted?
      !@alerts.empty?
    end
  end

  # Mock server – currently a no-op facade
  class MockServer; end

  # Mock logger to capture log calls
  class MockLogger
    attr_reader :messages

    def initialize
      @messages = []
    end

    def add(level, msg = nil, progname = nil, dump_log: false)
      @messages << { level: level, msg: msg }
    end
  end

  attr_accessor :sandbox, :sandbox_player, :sandbox_server,
                :sandbox_error, :sandbox_log_called,
                :sandbox_recurring_task, :sandbox_mock_logger,
                :sandbox_recurring_called

  def load_sandbox_library!
    # The Concurrent::TimerTask swap was done at file-load time in
    # SandboxTestSupport. Use require so SimpleCov tracks the single
    # load of the file.
    require 'aethyr/experiments/sandbox'
  end
end
World(SandboxWorld)

###############################################################################
# Given steps                                                                  #
###############################################################################

Given('I have a mock server and player for the sandbox') do
  load_sandbox_library!
  self.sandbox_server = SandboxWorld::MockServer.new
  self.sandbox_player = SandboxWorld::MockPlayer.new
end

Given('I have a sandbox instance') do
  load_sandbox_library!
  self.sandbox_server = SandboxWorld::MockServer.new
  self.sandbox_player = SandboxWorld::MockPlayer.new
  self.sandbox = Aethyr::Experiments::Sandbox.new(
    server: sandbox_server,
    player: sandbox_player,
    verbose: false
  )
end

Given('I have a sandbox instance with verbose false') do
  load_sandbox_library!
  self.sandbox_server = SandboxWorld::MockServer.new
  self.sandbox_player = SandboxWorld::MockPlayer.new
  self.sandbox_mock_logger = SandboxWorld::MockLogger.new
  self.sandbox_log_called = false
  self.sandbox = Aethyr::Experiments::Sandbox.new(
    server: sandbox_server,
    player: sandbox_player,
    verbose: false
  )
end

Given('I have a verbose sandbox instance') do
  load_sandbox_library!
  self.sandbox_server = SandboxWorld::MockServer.new
  self.sandbox_player = SandboxWorld::MockPlayer.new
  self.sandbox_mock_logger = SandboxWorld::MockLogger.new
  $LOG = sandbox_mock_logger
  self.sandbox = Aethyr::Experiments::Sandbox.new(
    server: sandbox_server,
    player: sandbox_player,
    verbose: true
  )
end

Given('I have a sandbox instance with CommandParser defined') do
  load_sandbox_library!
  self.sandbox_server = SandboxWorld::MockServer.new
  self.sandbox_player = SandboxWorld::MockPlayer.new
  self.sandbox = Aethyr::Experiments::Sandbox.new(
    server: sandbox_server,
    player: sandbox_player,
    verbose: false
  )

  # Define a CommandParser that returns a result string
  if defined?(::CommandParser)
    ::CommandParser.define_singleton_method(:parse) do |player, cmd|
      "parsed: #{cmd}"
    end
  else
    eval <<~RUBY, TOPLEVEL_BINDING
      module CommandParser
        def self.parse(player, cmd)
          "parsed: \#{cmd}"
        end
      end
    RUBY
  end
end

Given('I have a sandbox instance with CommandParser returning nil') do
  load_sandbox_library!
  self.sandbox_server = SandboxWorld::MockServer.new
  self.sandbox_player = SandboxWorld::MockPlayer.new
  self.sandbox = Aethyr::Experiments::Sandbox.new(
    server: sandbox_server,
    player: sandbox_player,
    verbose: false
  )

  if defined?(::CommandParser)
    ::CommandParser.define_singleton_method(:parse) do |player, cmd|
      nil
    end
  else
    eval <<~RUBY, TOPLEVEL_BINDING
      module CommandParser
        def self.parse(player, cmd)
          nil
        end
      end
    RUBY
  end
end

Given('I have a sandbox instance with CommandParser raising an error') do
  load_sandbox_library!
  self.sandbox_server = SandboxWorld::MockServer.new
  self.sandbox_player = SandboxWorld::MockPlayer.new
  self.sandbox = Aethyr::Experiments::Sandbox.new(
    server: sandbox_server,
    player: sandbox_player,
    verbose: false
  )

  if defined?(::CommandParser)
    ::CommandParser.define_singleton_method(:parse) do |player, cmd|
      raise "Something went wrong"
    end
  else
    eval <<~RUBY, TOPLEVEL_BINDING
      module CommandParser
        def self.parse(player, cmd)
          raise "Something went wrong"
        end
      end
    RUBY
  end
end

Given('I have a verbose sandbox instance with CommandParser raising an error') do
  load_sandbox_library!
  self.sandbox_server = SandboxWorld::MockServer.new
  self.sandbox_player = SandboxWorld::MockPlayer.new
  self.sandbox_mock_logger = SandboxWorld::MockLogger.new
  $LOG = sandbox_mock_logger
  self.sandbox = Aethyr::Experiments::Sandbox.new(
    server: sandbox_server,
    player: sandbox_player,
    verbose: true
  )

  if defined?(::CommandParser)
    ::CommandParser.define_singleton_method(:parse) do |player, cmd|
      raise "Something went wrong"
    end
  else
    eval <<~RUBY, TOPLEVEL_BINDING
      module CommandParser
        def self.parse(player, cmd)
          raise "Something went wrong"
        end
      end
    RUBY
  end
end

###############################################################################
# When steps                                                                   #
###############################################################################

When('I create a new Sandbox with verbose false') do
  self.sandbox = Aethyr::Experiments::Sandbox.new(
    server: sandbox_server,
    player: sandbox_player,
    verbose: false
  )
end

When('I create a new Sandbox with verbose true') do
  self.sandbox_mock_logger = SandboxWorld::MockLogger.new
  $LOG = sandbox_mock_logger
  self.sandbox = Aethyr::Experiments::Sandbox.new(
    server: sandbox_server,
    player: sandbox_player,
    verbose: true
  )
end

When('I enqueue sandbox command {string}') do |cmd|
  sandbox.command(cmd)
end

When('I enqueue sandbox command {string} at {int} seconds') do |cmd, seconds|
  sandbox.command(cmd, at: seconds)
end

When('I enqueue sandbox command {string} with past eta') do |cmd|
  # Directly push a command with a past ETA into the queue
  queue = sandbox.send(:command_queue)
  queue << { id: "test01", cmd: cmd, eta: Time.now - 10 }
end

When('I dispatch queued sandbox commands') do
  sandbox.send(:dispatch_queued_commands)
end

When('I schedule a recurring sandbox task every {int} seconds') do |seconds|
  self.sandbox_error = nil
  begin
    sandbox.every(seconds) { |sb| }
  rescue => e
    self.sandbox_error = e
  end
end

When('I schedule a recurring sandbox task that raises an error') do
  self.sandbox_error = nil
  self.sandbox_recurring_task = nil

  # Capture the FakeTimerTask created by schedule_recurring
  original_new = SandboxTestSupport::FakeTimerTask.method(:new)

  SandboxTestSupport::FakeTimerTask.define_singleton_method(:new) do |**opts, &blk|
    task = original_new.call(**opts, &blk)
    # Store the last created task for later inspection
    Thread.current[:last_sandbox_timer_task] = task
    task
  end

  begin
    sandbox.every(1) { |sb| raise "recurring task boom" }
    self.sandbox_recurring_task = Thread.current[:last_sandbox_timer_task]
  rescue => e
    self.sandbox_error = e
  ensure
    # Restore original new
    SandboxTestSupport::FakeTimerTask.define_singleton_method(:new, original_new)
  end
end

When('I execute the recurring sandbox task block') do
  self.sandbox_error = nil
  begin
    sandbox_recurring_task.execute_block if sandbox_recurring_task
  rescue => e
    self.sandbox_error = e
  end
end

When('I execute the sandbox scheduler block') do
  self.sandbox_error = nil
  begin
    scheduler = sandbox.instance_variable_get(:@scheduler)
    scheduler.execute_block
  rescue => e
    self.sandbox_error = e
  end
end

When('I schedule a recurring sandbox task that succeeds') do
  self.sandbox_error = nil
  self.sandbox_recurring_task = nil
  self.sandbox_recurring_called = false

  # Capture the FakeTimerTask created by schedule_recurring
  original_new = SandboxTestSupport::FakeTimerTask.method(:new)
  sandbox_world_ref = self

  SandboxTestSupport::FakeTimerTask.define_singleton_method(:new) do |**opts, &blk|
    task = original_new.call(**opts, &blk)
    Thread.current[:last_sandbox_timer_task] = task
    task
  end

  begin
    sandbox.every(1) { |sb| sandbox_world_ref.sandbox_recurring_called = true }
    self.sandbox_recurring_task = Thread.current[:last_sandbox_timer_task]
  rescue => e
    self.sandbox_error = e
  ensure
    SandboxTestSupport::FakeTimerTask.define_singleton_method(:new, original_new)
  end
end

When('I wait until the sandbox is idle') do
  self.sandbox_error = nil
  begin
    sandbox.wait_until_idle
  rescue => e
    self.sandbox_error = e
  end
end

When('I call sandbox log with message {string}') do |message|
  self.sandbox_log_called = false
  sandbox.log(message)
end

###############################################################################
# Then steps                                                                   #
###############################################################################

Then('the sandbox should be an instance of Aethyr::Experiments::Sandbox') do
  assert_instance_of(Aethyr::Experiments::Sandbox, sandbox)
end

Then('the sandbox player should be the mock player') do
  assert_same(sandbox_player, sandbox.player)
end

Then('the sandbox player method should return the player') do
  assert_same(sandbox_player, sandbox.player)
end

Then('the sandbox command queue should contain {int} entry') do |count|
  queue = sandbox.send(:command_queue)
  assert_equal(count, queue.size,
               "Expected #{count} entry in command queue, got #{queue.size}")
end

Then('the sandbox command queue entry should have cmd {string}') do |expected_cmd|
  queue = sandbox.send(:command_queue)
  assert_equal(expected_cmd, queue.first[:cmd])
end

Then('the sandbox command queue should be empty') do
  queue = sandbox.send(:command_queue)
  assert(queue.empty?, "Expected command queue to be empty, but it has #{queue.size} entries")
end

Then('the mock player should have received an alert') do
  assert(sandbox_player.alerted?,
         "Expected mock player to have received an alert")
end

Then('the mock player should not have received an alert') do
  assert(!sandbox_player.alerted?,
         "Expected mock player to NOT have received an alert")
end

Then('no error should be raised by the sandbox') do
  assert_nil(sandbox_error, "Expected no error but got: #{sandbox_error}")
end

Then('an ArgumentError should be raised by the sandbox with message {string}') do |message|
  assert_not_nil(sandbox_error, "Expected an ArgumentError but none was raised")
  assert_instance_of(ArgumentError, sandbox_error,
                     "Expected ArgumentError but got #{sandbox_error.class}")
  assert_equal(message, sandbox_error.message)
end

Then('the sandbox log should not have called super') do
  # When verbose is false, the log method returns early so $LOG should not have messages
  if sandbox_mock_logger
    assert(sandbox_mock_logger.messages.empty?,
           "Expected no log messages when verbose=false")
  end
end

Then('the sandbox log should have called super') do
  assert_not_nil(sandbox_mock_logger,
                 "Expected mock logger to be set up")
  assert(!sandbox_mock_logger.messages.empty?,
         "Expected log messages when verbose=true but got none")
end

Then('the sandbox log should have recorded a failure message') do
  assert_not_nil(sandbox_mock_logger,
                 "Expected mock logger to be set up")
  failure_logged = sandbox_mock_logger.messages.any? { |m| m[:msg].to_s.include?("failed") }
  assert(failure_logged,
         "Expected a 'failed' message in the log but got: #{sandbox_mock_logger.messages.inspect}")
end

Then('the sandbox recurring block should have been called') do
  assert(sandbox_recurring_called,
         "Expected recurring block to have been called")
end

Then('the sandbox log should have recorded a recurring error') do
  assert_not_nil(sandbox_mock_logger,
                 "Expected mock logger to be set up")
  recurring_error_logged = sandbox_mock_logger.messages.any? { |m| m[:msg].to_s.include?("Recurring task error") }
  assert(recurring_error_logged,
         "Expected a 'Recurring task error' message in the log but got: #{sandbox_mock_logger.messages.inspect}")
end
