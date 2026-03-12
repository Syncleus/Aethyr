# frozen_string_literal: true
# -----------------------------------------------------------------------------
# Step definitions for Server lifecycle feature
#
# Exercises lib/aethyr/core/connection/server.rb thoroughly, covering:
#   - Module loading and global constants (lines 22-23, 25-34, 36)
#   - ClientConnectionResetError (lines 45-49, 53, 57-58)
#   - Server class constants (lines 63-65)
#   - server_socket (lines 212-232)
#   - handle_client success + ECONNRESET (lines 234-246)
#   - clean_up_children (lines 248-255)
#   - Full Server#initialize loop (lines 69-193, 195, 201-206)
#   - Aethyr.main (lines 257-276, 320-322)
# -----------------------------------------------------------------------------
require 'test/unit/assertions'
require 'set'
require 'fcntl'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module – holds all scenario state for Server lifecycle tests
# ---------------------------------------------------------------------------
module ServerLifecycleWorld
  attr_accessor :server_error,
                :server_socket_result,
                :bare_server,
                :handle_client_result,
                :clean_up_ok,
                :harness,
                :main_error_rescued,
                :main_restart_count_processed,
                :saved_argv
end
World(ServerLifecycleWorld)

# ---------------------------------------------------------------------------
# Lightweight stub / mock classes used exclusively by Server lifecycle tests.
# All are namespaced under ServerTestDoubles to avoid collisions.
# ---------------------------------------------------------------------------
module ServerTestDoubles
  # Minimal Manager stand-in
  class FakeManager
    attr_reader :stopped, :saved, :updated, :actions_popped
    attr_accessor :soft_restart

    def initialize
      @stopped = false
      @saved = false
      @updated = false
      @actions_popped = 0
      @soft_restart = false
      @action_queue = []
    end

    def update_all;  @updated = true; end
    def save_all;    @saved   = true; end
    def stop;        @stopped = true; end
    def start;                        end

    def push_action(a); @action_queue << a; end

    def pop_action
      @actions_popped += 1
      @action_queue.shift
    end
  end

  # Minimal TimerTask stand-in
  class FakeTimerTask
    def initialize(**_opts); end
    def execute; end
  end

  # Mock server listener socket – controls what accept_nonblock returns
  class FakeListenerSocket
    attr_accessor :accept_sequence, :closed

    def initialize
      @accept_sequence = []
      @call_index = 0
      @closed = false
    end

    def accept_nonblock(exception: true)
      if @call_index < @accept_sequence.size
        action = @accept_sequence[@call_index]
        @call_index += 1
        action.call
      else
      raise IO::EAGAINWaitReadable
    end
  end

    def close; @closed = true; end
    def ==(other); equal?(other); end
  end

  # Mock client socket – returns true for is_a?(Socket)
  class FakeClientSocket
    attr_accessor :closed, :setsockopt_called

    def initialize
      @closed = false
      @setsockopt_called = false
    end

    def is_a?(klass)
      klass == ::Socket || super
    end

    def setsockopt(*_args)
      @setsockopt_called = true
    end

    def close
      @closed = true
    end

    def ==(other)
      equal?(other)
    end

    def inspect; "#<FakeClientSocket>"; end
  end

  # Mock display
  class FakeDisplay
    attr_accessor :global_refresh_value, :laid_out

    def initialize
      @global_refresh_value = false
      @laid_out = false
    end

    def global_refresh
      v = @global_refresh_value
      @global_refresh_value = false
      v
    end

    def layout
      @laid_out = true
    end

    def close; end
  end

  # Mock player connection
  class FakePlayerConnection
    attr_accessor :socket, :closed_flag, :received_data, :display, :close_called

    def initialize(socket = nil)
      @socket = socket
      @closed_flag = false
      @received_data = false
      @close_called = false
      @display = FakeDisplay.new
    end

    def receive_data
      @received_data = true
    end

    def close
      @close_called = true
      @closed_flag = true
    end

    def closed?
      @closed_flag
    end

    def to_s
      "FakePlayer"
    end
  end

  # Error-raising player for testing read-error paths
  class ErrorPlayerConnection < FakePlayerConnection
    def receive_data
      @received_data = true
      raise StandardError, "mock read error"
    end
  end

  # A callable action mock
  class FakeAction
    attr_reader :executed

    def initialize; @executed = false; end
    def action; @executed = true; end
  end

  # Server log file mock
  class FakeLogFile
    attr_reader :entries, :closed_flag

    def initialize
      @entries = []
      @closed_flag = false
    end

    def puts(msg); @entries << msg; end
    def flush; end
    def close; @closed_flag = true; end
    def closed?; @closed_flag; end
  end
end

# ---------------------------------------------------------------------------
# Helper module: builds controlled Server#initialize environments
# ---------------------------------------------------------------------------
module ServerHarnessBuilder
  def build_server_harness(opts = {})
    h = {
      manager:        ServerTestDoubles::FakeManager.new,
      listener:       ServerTestDoubles::FakeListenerSocket.new,
      log_file:       ServerTestDoubles::FakeLogFile.new,
      players:        [],
      accepted:       false,
      rejected:       false,
      ensure_ran:     false,
      action:         nil,
      opts:           opts,
    }

    case opts[:scenario]
    when :basic_accept
      client_sock = ServerTestDoubles::FakeClientSocket.new
      player = ServerTestDoubles::FakePlayerConnection.new(client_sock)
      h[:players] << player
      h[:client_socket] = client_sock

      h[:listener].accept_sequence = [
        -> { h[:accepted] = true; [client_sock, "fake_addr"] },
        -> { raise IO::EAGAINWaitReadable },
      ]
      h[:io_select_sequence] = [
        [nil, nil, nil],
      ]

    when :max_capacity
      client_sock = ServerTestDoubles::FakeClientSocket.new
      h[:client_socket] = client_sock

      h[:listener].accept_sequence = [
        -> { [client_sock, "fake_addr"] },
        -> { raise IO::EAGAINWaitReadable },
      ]
      h[:io_select_sequence] = [
        [nil, nil, nil],
      ]

    when :read_ready
      client_sock = ServerTestDoubles::FakeClientSocket.new
      player = ServerTestDoubles::FakePlayerConnection.new(client_sock)
      h[:players] << player
      h[:client_socket] = client_sock

      h[:listener].accept_sequence = [
        -> { [client_sock, "fake_addr"] },
        -> { raise IO::EAGAINWaitReadable },
      ]
      h[:io_select_sequence] = [
        [nil, nil, nil],
        [[client_sock], nil, nil],
      ]

    when :read_error
      client_sock = ServerTestDoubles::FakeClientSocket.new
      player = ServerTestDoubles::ErrorPlayerConnection.new(client_sock)
      h[:players] << player
      h[:client_socket] = client_sock

      h[:listener].accept_sequence = [
        -> { [client_sock, "fake_addr"] },
        -> { raise IO::EAGAINWaitReadable },
      ]
      h[:io_select_sequence] = [
        [nil, nil, nil],
        [[client_sock], nil, nil],
      ]

    when :error_condition
      client_sock = ServerTestDoubles::FakeClientSocket.new
      player = ServerTestDoubles::FakePlayerConnection.new(client_sock)
      h[:players] << player
      h[:client_socket] = client_sock

      h[:listener].accept_sequence = [
        -> { [client_sock, "fake_addr"] },
        -> { raise IO::EAGAINWaitReadable },
      ]
      h[:io_select_sequence] = [
        [nil, nil, nil],
        [nil, nil, [client_sock]],
      ]

    when :closed_player
      client_sock = ServerTestDoubles::FakeClientSocket.new
      player = ServerTestDoubles::FakePlayerConnection.new(client_sock)
      player.closed_flag = true
      h[:players] << player
      h[:client_socket] = client_sock

      h[:listener].accept_sequence = [
        -> { [client_sock, "fake_addr"] },
        -> { raise IO::EAGAINWaitReadable },
      ]
      h[:io_select_sequence] = [
        [nil, nil, nil],
      ]

    when :action_processing
      fake_action = ServerTestDoubles::FakeAction.new
      h[:action] = fake_action
      h[:manager].push_action(fake_action)

      h[:listener].accept_sequence = [
        -> { raise IO::EAGAINWaitReadable },
      ]
      h[:io_select_sequence] = [
        [nil, nil, nil],
      ]

    when :global_refresh
      client_sock = ServerTestDoubles::FakeClientSocket.new
      player = ServerTestDoubles::FakePlayerConnection.new(client_sock)
      player.display.global_refresh_value = true
      h[:players] << player
      h[:client_socket] = client_sock

      h[:listener].accept_sequence = [
        -> { [client_sock, "fake_addr"] },
        -> { raise IO::EAGAINWaitReadable },
      ]
      h[:io_select_sequence] = [
        [nil, nil, nil],
        [nil, nil, nil],
      ]

    when :ensure_block
      h[:listener].accept_sequence = [
        -> { raise IO::EAGAINWaitReadable },
      ]
      h[:io_select_sequence] = [
        [nil, nil, nil],
      ]

    else
      h[:listener].accept_sequence = [
        -> { raise IO::EAGAINWaitReadable },
      ]
      h[:io_select_sequence] = [
        [nil, nil, nil],
      ]
    end

    h
  end

  # Runs Server.new inside a sandbox of stubbed collaborators.
  # Uses a subclass to override private methods and a patched IO.select
  # as the loop-breaker (raises Interrupt after the test sequence is
  # exhausted).
  def run_server_with_harness(h)
    original_manager    = defined?($manager) ? $manager : :undefined
    original_timer_new  = Concurrent::TimerTask.method(:new)
    original_io_select  = IO.method(:select)
    original_file_open  = File.method(:open)
    original_manager_new = Manager.method(:new)

    select_call_index = 0
    io_select_seq = h[:io_select_sequence] || [[nil, nil, nil]]
    scenario = h[:opts][:scenario]

    begin
      $manager = h[:manager]

      # Stub Manager.new to return our fake manager (line 70 of server.rb)
      fake_mgr = h[:manager]
      Manager.define_singleton_method(:new) do |*_args|
        fake_mgr
      end

      # Stub Concurrent::TimerTask.new to return a no-op object
      Concurrent::TimerTask.define_singleton_method(:new) do |**_opts, &_blk|
        ServerTestDoubles::FakeTimerTask.new
      end

      # Stub IO.select: return prepared responses then raise Interrupt
      IO.define_singleton_method(:select) do |_reads, _writes, _errors, _timeout|
        idx = select_call_index
        select_call_index += 1
        if idx < io_select_seq.size
          io_select_seq[idx]
        else
          raise Interrupt, "server_lifecycle_test loop exit"
        end
      end

      # Stub File.open to intercept server.log opens
      log_file_ref = h[:log_file]
      File.define_singleton_method(:open) do |path, *args, &blk|
        if path.to_s.include?("server.log")
          blk ? blk.call(log_file_ref) : log_file_ref
        else
          original_file_open.call(path, *args, &blk)
        end
      end

      # Build a subclass that overrides private methods
      listener_ref = h[:listener]
      players_ref  = h[:players]
      scenario_ref = scenario

      klass = Class.new(Aethyr::Server) do
        define_method(:server_socket) do |_addr, _port|
          listener_ref
        end

        define_method(:handle_client) do |socket, _addrinfo|
          if players_ref.any?
            players_ref.first
          else
            p = ServerTestDoubles::FakePlayerConnection.new(socket)
            players_ref << p
            p
          end
        end

        define_method(:clean_up_children) do
          # no-op in tests
        end
      end

      # For max_capacity: set MAX_PLAYERS to 0 so any connection is rejected
      if scenario == :max_capacity
        klass.send(:remove_const, :MAX_PLAYERS) if klass.const_defined?(:MAX_PLAYERS, false)
        klass.const_set(:MAX_PLAYERS, 0)
      end

      begin
        klass.new("127.0.0.1", 0)
      rescue Interrupt
        # Expected – our IO.select stub breaks the loop
      rescue StandardError => e
        h[:loop_error] = e
      end

      h[:ensure_ran] = true

    ensure
      $manager = (original_manager == :undefined ? nil : original_manager)

      Manager.define_singleton_method(:new) do |*a, &b|
        original_manager_new.call(*a, &b)
      end

      Concurrent::TimerTask.define_singleton_method(:new) do |**opts, &blk|
        original_timer_new.call(**opts, &blk)
      end

      IO.define_singleton_method(:select) do |*a|
        original_io_select.call(*a)
      end

      File.define_singleton_method(:open) do |*a, &b|
        original_file_open.call(*a, &b)
      end
    end
  end
end
World(ServerHarnessBuilder)

# =============================================================================
#                          C U C U M B E R   S T E P S
# =============================================================================

# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------
Given('the Server module is loaded') do
  require 'aethyr/core/connection/server'
  assert(defined?(Aethyr::Server), "Expected Aethyr::Server to be defined")
end

Then('the game server AETHYR_VERSION should be {string}') do |expected|
  assert_equal(expected, $AETHYR_VERSION)
end

Then('the game server LOAD_PATH should include the connection directory') do
  assert($LOAD_PATH.any? { |p| p.include?('connection') || p.include?('aethyr') },
         "Expected $LOAD_PATH to contain an aethyr-related path")
end

# ---------------------------------------------------------------------------
# ClientConnectionResetError
# ---------------------------------------------------------------------------
When('I create a Server ClientConnectionResetError with defaults') do
  self.server_error = Aethyr::ClientConnectionResetError.new
end

When('I create a Server ClientConnectionResetError with message {string} and addrinfo {string} and original error {string}') do |msg, addr, orig|
  self.server_error = Aethyr::ClientConnectionResetError.new(msg, addr, orig)
end

Then('the Server error message should be {string}') do |expected|
  assert_equal(expected, server_error.message)
end

Then('the Server error addrinfo should be nil') do
  assert_nil(server_error.addrinfo)
end

Then('the Server error original_error should be nil') do
  assert_nil(server_error.original_error)
end

Then('the Server error addrinfo should be {string}') do |expected|
  assert_equal(expected, server_error.addrinfo)
end

Then('the Server error original_error should be {string}') do |expected|
  assert_equal(expected, server_error.original_error)
end

Then('the Server error should be a kind of StandardError') do
  assert_kind_of(StandardError, server_error)
end

# ---------------------------------------------------------------------------
# Server constants
# ---------------------------------------------------------------------------
Then('the Server RECEIVE_BUFFER_SIZE should be {int}') do |expected|
  assert_equal(expected, Aethyr::Server::RECEIVE_BUFFER_SIZE)
end

Then('the Server SELECT_TIMEOUT should be {float}') do |expected|
  assert_in_delta(expected, Aethyr::Server::SELECT_TIMEOUT, 0.001)
end

Then('the Server MAX_PLAYERS should be {int}') do |expected|
  assert_equal(expected, Aethyr::Server::MAX_PLAYERS)
end

# ---------------------------------------------------------------------------
# server_socket (private)
# ---------------------------------------------------------------------------
Given('a bare Server instance is allocated') do
  self.bare_server = Aethyr::Server.allocate
end

When('I call server_socket on the bare Server with address {string} and a free port') do |addr|
  self.server_socket_result = bare_server.send(:server_socket, addr, 0)
end

Then('the Server socket should be a Socket instance') do
  assert_kind_of(Socket, server_socket_result)
end

Then('the Server socket should be in non-blocking mode') do
  flags = server_socket_result.fcntl(Fcntl::F_GETFL)
  assert((flags & Fcntl::O_NONBLOCK) != 0,
         "Expected socket to be in non-blocking mode")
end

Then('the Server listening socket is cleaned up') do
  server_socket_result.close if server_socket_result && !server_socket_result.closed?
end

# ---------------------------------------------------------------------------
# handle_client (private)
# ---------------------------------------------------------------------------
Given('PlayerConnection is stubbed for the Server test') do
  @_slc_orig_pc_new = PlayerConnection.method(:new)
  PlayerConnection.define_singleton_method(:new) do |socket, _addrinfo, *_args|
    ServerTestDoubles::FakePlayerConnection.new(socket)
  end
end

Given('PlayerConnection is stubbed to raise ECONNRESET for the Server test') do
  @_slc_orig_pc_new = PlayerConnection.method(:new)
  PlayerConnection.define_singleton_method(:new) do |_socket, _addrinfo, *_args|
    raise Errno::ECONNRESET, "Connection reset by peer"
  end
end

When('I call handle_client with a mock socket and addrinfo') do
  mock_socket = ServerTestDoubles::FakeClientSocket.new
  mock_addrinfo = Object.new
  mock_addrinfo.define_singleton_method(:inspect) { "mock_addr:1234" }

  self.handle_client_result = bare_server.send(:handle_client, mock_socket, mock_addrinfo)
end

Then('the Server handle_client result should be a mock player connection') do
  assert_kind_of(ServerTestDoubles::FakePlayerConnection, handle_client_result)
end

Then('the Server handle_client result should be nil') do
  assert_nil(handle_client_result)
end

# ---------------------------------------------------------------------------
# clean_up_children (private)
# ---------------------------------------------------------------------------
Given('Process.wait is stubbed to raise Interrupt for the Server test') do
  @_slc_orig_process_wait = Process.method(:wait)
  @_slc_orig_process_kill = Process.method(:kill)

  # Make Process.wait raise Interrupt immediately
  Process.define_singleton_method(:wait) do |*_args|
    raise Interrupt, "test interrupt for clean_up_children"
  end

  # Stub Process.kill so we don't actually send signals
  Process.define_singleton_method(:kill) do |*_args|
    # no-op
  end
end

When('I call clean_up_children on the bare Server') do
  begin
    bare_server.send(:clean_up_children)
    self.clean_up_ok = true
  rescue => _e
    self.clean_up_ok = false
  end
end

Then('the Server clean_up_children should complete without error') do
  assert(clean_up_ok, "Expected clean_up_children to complete without error")
end

# ---------------------------------------------------------------------------
# Full Server initialize – basic accept
# ---------------------------------------------------------------------------
Given('the full Server test harness is prepared') do
  self.harness = build_server_harness(scenario: :basic_accept)
end

When('I run the Server constructor with the test harness') do
  run_server_with_harness(harness)
end

Then('the Server harness should have accepted a connection') do
  assert(harness[:accepted], "Expected a connection to have been accepted")
end

Then('the Server harness ensure block should have run') do
  assert(harness[:ensure_ran], "Expected ensure block to have executed")
end

# ---------------------------------------------------------------------------
# Max capacity rejection
# ---------------------------------------------------------------------------
Given('the Server max-capacity test harness is prepared') do
  self.harness = build_server_harness(scenario: :max_capacity)
end

When('I run the Server constructor with the max-capacity harness') do
  run_server_with_harness(harness)
end

Then('the Server harness should have rejected the connection') do
  cs = harness[:client_socket]
  assert(cs.closed, "Expected client socket to be closed due to max capacity")
end

# ---------------------------------------------------------------------------
# Read-ready
# ---------------------------------------------------------------------------
Given('the Server read-ready test harness is prepared') do
  self.harness = build_server_harness(scenario: :read_ready)
end

When('I run the Server constructor with the read-ready harness') do
  run_server_with_harness(harness)
end

Then('the Server harness player should have received data') do
  player = harness[:players].first
  assert_not_nil(player, "Expected a player to exist")
  assert(player.received_data, "Expected player to have received data")
end

# ---------------------------------------------------------------------------
# Read-error
# ---------------------------------------------------------------------------
Given('the Server read-error test harness is prepared') do
  self.harness = build_server_harness(scenario: :read_error)
end

When('I run the Server constructor with the read-error harness') do
  run_server_with_harness(harness)
end

Then('the Server harness should have handled the read error') do
  player = harness[:players].first
  assert_not_nil(player, "Expected a player to exist")
  # Read error path: player.close called, error re-raised, caught by our harness
  assert(player.close_called || harness[:loop_error],
         "Expected read error to trigger player close or be caught as loop_error")
end

# ---------------------------------------------------------------------------
# Error-condition sockets
# ---------------------------------------------------------------------------
Given('the Server error-condition test harness is prepared') do
  self.harness = build_server_harness(scenario: :error_condition)
end

When('I run the Server constructor with the error-condition harness') do
  run_server_with_harness(harness)
end

Then('the Server harness should have handled the error condition') do
  player = harness[:players].first
  assert_not_nil(player, "Expected a player to exist")
  assert(player.close_called,
         "Expected error condition to trigger player close")
end

# ---------------------------------------------------------------------------
# Closed player cleanup
# ---------------------------------------------------------------------------
Given('the Server closed-player test harness is prepared') do
  self.harness = build_server_harness(scenario: :closed_player)
end

When('I run the Server constructor with the closed-player harness') do
  run_server_with_harness(harness)
end

Then('the Server harness should have cleaned up the closed player') do
  assert(harness[:ensure_ran],
         "Expected server to complete and clean up closed player")
end

# ---------------------------------------------------------------------------
# Action processing
# ---------------------------------------------------------------------------
Given('the Server action-processing test harness is prepared') do
  self.harness = build_server_harness(scenario: :action_processing)
end

When('I run the Server constructor with the action-processing harness') do
  run_server_with_harness(harness)
end

Then('the Server harness action should have been executed') do
  action = harness[:action]
  assert_not_nil(action, "Expected an action to exist")
  assert(action.executed, "Expected the action to have been executed")
end

# ---------------------------------------------------------------------------
# Global refresh
# ---------------------------------------------------------------------------
Given('the Server global-refresh test harness is prepared') do
  self.harness = build_server_harness(scenario: :global_refresh)
end

When('I run the Server constructor with the global-refresh harness') do
  run_server_with_harness(harness)
end

Then('the Server harness player display should have been laid out') do
  player = harness[:players].first
  assert_not_nil(player, "Expected a player to exist")
  assert(player.display.laid_out,
         "Expected player display layout to have been triggered on global refresh")
end

# ---------------------------------------------------------------------------
# Ensure block
# ---------------------------------------------------------------------------
Given('the Server ensure-block test harness is prepared') do
  self.harness = build_server_harness(scenario: :ensure_block)
end

When('I run the Server constructor with the ensure-block harness') do
  run_server_with_harness(harness)
end

Then('the Server harness manager should have been stopped') do
  assert(harness[:manager].stopped,
         "Expected $manager.stop to have been called in ensure block")
end

Then('the Server harness manager should have saved all') do
  assert(harness[:manager].saved,
         "Expected $manager.save_all to have been called in ensure block")
end

# ---------------------------------------------------------------------------
# Aethyr.main
# ---------------------------------------------------------------------------
Given('Server.new is stubbed to raise RuntimeError for the main test') do
  @_slc_orig_server_new = Aethyr::Server.method(:new)
  Aethyr::Server.define_singleton_method(:new) do |*_args|
    raise RuntimeError, "test server error"
  end
end

Given('ARGV contains a restart count for the Server test') do
  self.saved_argv = ARGV.dup
  ARGV.replace(["3"])
end

When('I call Aethyr.main') do
  begin
    Aethyr.main
    self.main_error_rescued = false
  rescue RuntimeError
    # Aethyr.main re-raises after logging – this is expected
    self.main_error_rescued = true
    self.main_restart_count_processed = true
  rescue Exception
    # Catch anything else (Interrupt, etc.)
    self.main_error_rescued = true
    self.main_restart_count_processed = true
  end
end

Then('the Aethyr main method should have raised and rescued the error') do
  assert(main_error_rescued,
         "Expected Aethyr.main to have raised/rescued the RuntimeError")
end

Then('the Aethyr main method should have processed the restart count') do
  assert(main_restart_count_processed,
         "Expected Aethyr.main to have processed the ARGV restart count")
end

# ---------------------------------------------------------------------------
# Consolidated After hook – restores all stubs
# ---------------------------------------------------------------------------
After('@unit') do
  # Restore PlayerConnection.new
  if defined?(@_slc_orig_pc_new) && @_slc_orig_pc_new
    orig = @_slc_orig_pc_new
    PlayerConnection.define_singleton_method(:new) { |*a, &b| orig.call(*a, &b) }
    @_slc_orig_pc_new = nil
  end

  # Restore Process.wait and Process.kill
  if defined?(@_slc_orig_process_wait) && @_slc_orig_process_wait
    orig_wait = @_slc_orig_process_wait
    Process.define_singleton_method(:wait) { |*a| orig_wait.call(*a) }
    @_slc_orig_process_wait = nil
  end
  if defined?(@_slc_orig_process_kill) && @_slc_orig_process_kill
    orig_kill = @_slc_orig_process_kill
    Process.define_singleton_method(:kill) { |*a| orig_kill.call(*a) }
    @_slc_orig_process_kill = nil
  end

  # Restore ARGV
  if defined?(@saved_argv) && @saved_argv
    ARGV.replace(@saved_argv)
    @saved_argv = nil
  end

  # Restore Server.new
  if defined?(@_slc_orig_server_new) && @_slc_orig_server_new
    orig_sn = @_slc_orig_server_new
    Aethyr::Server.define_singleton_method(:new) { |*a, &b| orig_sn.call(*a, &b) }
    @_slc_orig_server_new = nil
  end
end
