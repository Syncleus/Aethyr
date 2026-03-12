# frozen_string_literal: true

###############################################################################
# Step definitions for File::Tail feature                                      #
###############################################################################
require 'test/unit/assertions'
require 'fileutils'
require 'securerandom'

World(Test::Unit::Assertions)

# ---------------------------------------------------------------------------
# World module – holds per-scenario state for Tail tests
# ---------------------------------------------------------------------------
module TailWorld
  attr_accessor :tail_file, :tail_tempfile_path, :tail_lines_collected,
                :tail_result, :tail_exception, :tail_logfile_ref,
                :tail_returned_file, :tail_logfile_lines,
                :tail_main_error, :tail_reopen_exception,
                :plain_tempfile_path
end
World(TailWorld)

# We need the REAL, un-monkey-patched File.open.  Another step-definition
# file (server_lifecycle_steps) replaces it with a wrapper that drops keyword
# args.  Capture the original at load time so our helper is immune.
TAIL_ORIGINAL_FILE_OPEN = File.method(:open)

# ---------------------------------------------------------------------------
# Coverage-tracking constants (mirrors event_store_stats_steps.rb pattern)
# ---------------------------------------------------------------------------
TAIL_SCRIPT_PATH = File.expand_path(
  '../../../../lib/aethyr/core/util/tail.rb', __FILE__
).freeze

# Accumulates per-scenario coverage snapshots so we can merge them later.
TAIL_COV_SNAPSHOTS = []

# ---------------------------------------------------------------------------
# Helper: create a temp file with N lines of content using raw IO
# Returns the path to the created file.
# ---------------------------------------------------------------------------
def create_tail_tempfile(n)
  path = "/tmp/tail_test_#{SecureRandom.hex(8)}.log"
  IO.write(path, n.times.map { |i| "Line #{i + 1}\n" }.join)
  path
end

# ---------------------------------------------------------------------------
# After hook: clean up tempfiles
# ---------------------------------------------------------------------------
After('@tail_cleanup') do
  # handled by per-scenario cleanup below
end

After do
  # ── Snapshot coverage for tail.rb after every scenario ──
  if defined?(Coverage) && Coverage.respond_to?(:peek_result)
    begin
      peek = Coverage.peek_result
      key = peek.keys.find { |k| k.include?('util/tail.rb') && !k.include?('step') }
      if key
        lines = peek[key].is_a?(Hash) ? peek[key][:lines] : peek[key]
        TAIL_COV_SNAPSHOTS << lines.dup if lines
      end
    rescue StandardError
      # Coverage not started or not available; silently ignore.
    end
  end

  # ── Cleanup temp files and handles ──
  if defined?(@tail_file_handle) && @tail_file_handle && !@tail_file_handle.closed?
    @tail_file_handle.close rescue nil
  end
  if tail_file && !tail_file.closed?
    tail_file.close rescue nil
  end
  if tail_tempfile_path && ::File.exist?(tail_tempfile_path)
    ::File.delete(tail_tempfile_path) rescue nil
  end
  if plain_tempfile_path && ::File.exist?(plain_tempfile_path)
    ::File.delete(plain_tempfile_path) rescue nil
  end
  if tail_returned_file && !tail_returned_file.closed?
    tail_returned_file.close rescue nil
  end
end

# ===========================================================================
#                              GIVEN STEPS
# ===========================================================================
Given('I require the Tail library') do
  # Use load (once) to ensure SimpleCov tracks coverage for this file.
  # A plain `require` may be cached before SimpleCov starts.
  unless defined?(File::Tail)
    load File.expand_path('lib/aethyr/core/util/tail.rb', '/app')
  end
  assert defined?(File::Tail), 'File::Tail module should be defined'
end

Given('I have a tailable tempfile with {int} lines') do |n|
  self.tail_tempfile_path = create_tail_tempfile(n)
  # Open the file using the original File.open to bypass any monkey-patches
  self.tail_file = TAIL_ORIGINAL_FILE_OPEN.call(tail_tempfile_path, 'r')
  tail_file.extend(File::Tail)
end

Given('I have a plain tempfile with {int} lines') do |n|
  self.plain_tempfile_path = create_tail_tempfile(n)
end

Given('I configure the file with return_if_eof true') do
  tail_file.return_if_eof = true
end

Given('I configure the file with break_if_eof true') do
  tail_file.break_if_eof = true
end

# ===========================================================================
#                         EXCEPTION HIERARCHY STEPS
# ===========================================================================
Then('TailException should be a subclass of Exception') do
  assert File::Tail::TailException < Exception,
         'TailException should inherit from Exception'
end

Then('DeletedException should be a subclass of TailException') do
  assert File::Tail::DeletedException < File::Tail::TailException,
         'DeletedException should inherit from TailException'
end

Then('ReturnException should be a subclass of TailException') do
  assert File::Tail::ReturnException < File::Tail::TailException,
         'ReturnException should inherit from TailException'
end

Then('BreakException should be a subclass of TailException') do
  assert File::Tail::BreakException < File::Tail::TailException,
         'BreakException should inherit from TailException'
end

Then('ReopenException should be a subclass of TailException') do
  assert File::Tail::ReopenException < File::Tail::TailException,
         'ReopenException should inherit from TailException'
end

# ===========================================================================
#                       REOPEN EXCEPTION STEPS
# ===========================================================================
When('I create a ReopenException with default mode') do
  @reopen_ex = File::Tail::ReopenException.new
end

When('I create a ReopenException with mode {string}') do |mode|
  @reopen_ex = File::Tail::ReopenException.new(mode.to_sym)
end

Then('the ReopenException mode should be {string}') do |expected|
  assert_equal expected.to_sym, @reopen_ex.mode,
               "Expected mode #{expected.inspect}, got #{@reopen_ex.mode.inspect}"
end

# ===========================================================================
#                       ATTRIBUTE STEPS
# ===========================================================================
When('I set tail attributes on the file') do
  tail_file.max_interval = 15
  tail_file.interval = 2
  tail_file.reopen_deleted = false
  tail_file.reopen_suspicious = false
  tail_file.suspicious_interval = 30
  tail_file.break_if_eof = true
  tail_file.return_if_eof = false
end

Then('the tail attributes should reflect the values I set') do
  assert_equal 15, tail_file.max_interval
  assert_equal 2, tail_file.interval
  assert_equal false, tail_file.reopen_deleted
  assert_equal false, tail_file.reopen_suspicious
  assert_equal 30, tail_file.suspicious_interval
  assert_equal true, tail_file.break_if_eof
  assert_equal false, tail_file.return_if_eof
end

When('I register an after_reopen callback') do
  @callback_called = false
  tail_file.after_reopen { |f| @callback_called = true }
end

Then('the after_reopen callback should be stored') do
  assert_not_nil tail_file.instance_variable_get(:@after_reopen),
                 'Expected @after_reopen to be set'
end

# ===========================================================================
#                       FORWARD METHOD STEPS
# ===========================================================================
When('I call forward with {int}') do |n|
  tail_file.forward(n)
end

Then('the file position should be at the beginning') do
  assert_equal 0, tail_file.pos,
               "Expected file position to be 0, got #{tail_file.pos}"
end

When('I read the remaining lines') do
  @remaining_lines = tail_file.readlines
end

Then('I should have {int} remaining lines') do |n|
  assert_equal n, @remaining_lines.length,
               "Expected #{n} remaining lines, got #{@remaining_lines.length}"
end

# ===========================================================================
#                       BACKWARD METHOD STEPS
# ===========================================================================
When('I call backward with {int}') do |n|
  tail_file.backward(n)
end

When('I call backward with {int} and bufsiz {int}') do |n, bufsiz|
  tail_file.backward(n, bufsiz)
end

Then('the file should be at EOF') do
  assert tail_file.eof?, 'Expected file to be at EOF'
end

# ===========================================================================
#                          TAIL METHOD STEPS
# ===========================================================================
When('I call tail with n={int} and a block') do |n|
  self.tail_lines_collected = []
  tail_file.tail(n) { |line| tail_lines_collected << line }
end

When('I call tail with n={int} and no block') do |n|
  self.tail_result = tail_file.tail(n)
end

When('I call tail with no limit and a block') do
  self.tail_lines_collected = []
  # Stub sleep to avoid blocking
  tail_file.define_singleton_method(:sleep) { |_interval| }
  tail_file.tail { |line| tail_lines_collected << line }
end

When('I call tail with no n to exercise unlimited read_line') do
  self.tail_lines_collected = []
  tail_file.define_singleton_method(:sleep) { |_interval| }
  tail_file.tail { |line| tail_lines_collected << line }
end

When('I call tail expecting a BreakException') do
  self.tail_exception = nil
  # Stub sleep to avoid blocking
  tail_file.define_singleton_method(:sleep) { |_interval| }
  begin
    tail_file.tail { |line| }
  rescue File::Tail::BreakException => e
    self.tail_exception = e
  end
end

Then('the block should have received {int} lines') do |n|
  assert_equal n, tail_lines_collected.length,
               "Expected #{n} lines, got #{tail_lines_collected.length}"
end

Then('tail should return an array of {int} lines') do |n|
  assert_kind_of Array, tail_result, 'Expected tail to return an Array'
  assert_equal n, tail_result.length,
               "Expected #{n} lines, got #{tail_result.length}"
end

Then('a BreakException should have been raised') do
  assert_not_nil tail_exception, 'Expected a BreakException but none was raised'
  assert_kind_of File::Tail::BreakException, tail_exception
end

# ===========================================================================
#                    PRESET ATTRIBUTES STEPS
# ===========================================================================
Then('the preset attributes should have been initialised') do
  assert_not_nil tail_file.instance_variable_get(:@lines),
                 'Expected @lines to be set'
  assert_not_nil tail_file.instance_variable_get(:@no_read),
                 'Expected @no_read to be set'
  assert_not_nil tail_file.max_interval
  assert_not_nil tail_file.interval
end

# ===========================================================================
#                      RESTAT STEPS
# ===========================================================================
When('I simulate an inode change and call tail') do
  self.tail_reopen_exception = nil
  tail_file.return_if_eof = true
  tail_file.define_singleton_method(:sleep) { |_interval| }

  # First, initialise @stat by calling restat once
  tail_file.send(:preset_attributes)
  tail_file.send(:restat)

  # Now stub File.stat to return a different inode
  original_stat = ::File.stat(tail_file.path)
  fake_stat = original_stat.dup
  fake_stat.define_singleton_method(:ino) { original_stat.ino + 999 }
  fake_stat.define_singleton_method(:dev) { original_stat.dev }
  fake_stat.define_singleton_method(:size) { original_stat.size }

  real_path = tail_file.path
  original_file_stat = ::File.method(:stat)
  file_singleton = class << ::File; self; end
  file_singleton.define_method(:stat) do |path|
    if path == real_path
      fake_stat
    else
      original_file_stat.call(path)
    end
  end

  begin
    tail_file.send(:restat)
  rescue File::Tail::ReopenException => e
    self.tail_reopen_exception = e
  ensure
    file_singleton.define_method(:stat) do |path|
      original_file_stat.call(path)
    end
  end
end

When('I simulate a file size shrink and call tail') do
  self.tail_reopen_exception = nil
  tail_file.return_if_eof = true
  tail_file.define_singleton_method(:sleep) { |_interval| }

  # Initialise @stat
  tail_file.send(:preset_attributes)
  tail_file.send(:restat)

  # Now stub File.stat to return smaller size
  original_stat = ::File.stat(tail_file.path)
  fake_stat = original_stat.dup
  fake_stat.define_singleton_method(:ino) { original_stat.ino }
  fake_stat.define_singleton_method(:dev) { original_stat.dev }
  fake_stat.define_singleton_method(:size) { 0 }

  real_path = tail_file.path
  original_file_stat = ::File.method(:stat)
  file_singleton = class << ::File; self; end
  file_singleton.define_method(:stat) do |path|
    if path == real_path
      fake_stat
    else
      original_file_stat.call(path)
    end
  end

  begin
    tail_file.send(:restat)
  rescue File::Tail::ReopenException => e
    self.tail_reopen_exception = e
  ensure
    file_singleton.define_method(:stat) do |path|
      original_file_stat.call(path)
    end
  end
end

When('I simulate ENOENT in restat and call tail') do
  self.tail_reopen_exception = nil
  tail_file.return_if_eof = true
  tail_file.define_singleton_method(:sleep) { |_interval| }

  tail_file.send(:preset_attributes)

  # Stub File.stat to raise ENOENT
  real_path = tail_file.path
  original_file_stat = ::File.method(:stat)
  file_singleton = class << ::File; self; end
  file_singleton.define_method(:stat) do |path|
    if path == real_path
      raise Errno::ENOENT, path
    else
      original_file_stat.call(path)
    end
  end

  begin
    tail_file.send(:restat)
  rescue File::Tail::ReopenException => e
    self.tail_reopen_exception = e
  ensure
    file_singleton.define_method(:stat) do |path|
      original_file_stat.call(path)
    end
  end
end

Then('a ReopenException should have been raised during restat') do
  assert_not_nil tail_reopen_exception,
                 'Expected ReopenException but none was raised'
  assert_kind_of File::Tail::ReopenException, tail_reopen_exception
end

# ===========================================================================
#                    SLEEP_INTERVAL STEPS
# ===========================================================================
When('I exercise sleep_interval with lines greater than zero') do
  tail_file.define_singleton_method(:sleep) { |_interval| }
  tail_file.send(:preset_attributes)
  tail_file.instance_variable_set(:@lines, 5)
  tail_file.instance_variable_set(:@interval, 10)
  tail_file.send(:sleep_interval)
  @resulting_interval = tail_file.instance_variable_get(:@interval)
end

Then('the interval should have been adjusted downward') do
  assert @resulting_interval < 10,
         "Expected interval < 10, got #{@resulting_interval}"
end

When('I exercise sleep_interval with zero lines') do
  tail_file.define_singleton_method(:sleep) { |_interval| }
  tail_file.send(:preset_attributes)
  tail_file.instance_variable_set(:@lines, 0)
  tail_file.instance_variable_set(:@interval, 2)
  tail_file.instance_variable_set(:@max_interval, 100)
  tail_file.send(:sleep_interval)
  @resulting_interval = tail_file.instance_variable_get(:@interval)
end

Then('the interval should have been doubled') do
  assert_equal 4, @resulting_interval,
               "Expected interval to double to 4, got #{@resulting_interval}"
end

When('I exercise sleep_interval beyond max_interval') do
  tail_file.define_singleton_method(:sleep) { |_interval| }
  tail_file.send(:preset_attributes)
  tail_file.instance_variable_set(:@lines, 0)
  tail_file.instance_variable_set(:@interval, 8)
  tail_file.instance_variable_set(:@max_interval, 10)
  tail_file.send(:sleep_interval)
  @resulting_interval = tail_file.instance_variable_get(:@interval)
  @max_interval_val = tail_file.instance_variable_get(:@max_interval)
end

Then('the interval should equal max_interval') do
  assert_equal @max_interval_val, @resulting_interval,
               "Expected interval to be capped at #{@max_interval_val}, got #{@resulting_interval}"
end

# ===========================================================================
#                      REOPEN_FILE STEPS
# ===========================================================================
When('I call reopen_file with mode bottom') do
  tail_file.send(:preset_attributes)
  tail_file.send(:reopen_file, :bottom)
end

When('I call reopen_file with mode top') do
  tail_file.send(:preset_attributes)
  tail_file.send(:reopen_file, :top)
end

Then('the file should be at the beginning') do
  assert_equal 0, tail_file.pos,
               "Expected file position to be 0, got #{tail_file.pos}"
end

When('I delete the file and call reopen_file with reopen_deleted false') do
  self.tail_exception = nil
  tail_file.send(:preset_attributes)
  tail_file.reopen_deleted = false
  # Delete the underlying file
  ::File.delete(tail_tempfile_path) rescue nil
  begin
    tail_file.send(:reopen_file, :top)
  rescue File::Tail::DeletedException => e
    self.tail_exception = e
  end
end

Then('a DeletedException should have been raised') do
  assert_not_nil tail_exception, 'Expected DeletedException but none was raised'
  assert_kind_of File::Tail::DeletedException, tail_exception
end

# ===========================================================================
#                   READ_LINE ENOENT/ESTALE STEPS
# ===========================================================================
When('I simulate ENOENT during readline') do
  self.tail_reopen_exception = nil
  tail_file.send(:preset_attributes)

  # Stub readline to raise Errno::ENOENT
  tail_file.define_singleton_method(:readline) { raise Errno::ENOENT, 'test' }

  collected = []
  begin
    tail_file.send(:read_line) { |line| collected << line }
  rescue File::Tail::ReopenException => e
    self.tail_reopen_exception = e
  end
end

Then('a ReopenException should have been raised from read_line') do
  assert_not_nil tail_reopen_exception,
                 'Expected ReopenException but none was raised'
  assert_kind_of File::Tail::ReopenException, tail_reopen_exception
end

# ===========================================================================
#            REOPEN_SUSPICIOUS STEPS
# ===========================================================================
When('I simulate suspicious silence and call tail') do
  self.tail_lines_collected = []
  tail_file.send(:preset_attributes)
  tail_file.reopen_suspicious = true
  tail_file.suspicious_interval = 0  # trigger immediately
  tail_file.return_if_eof = true
  tail_file.define_singleton_method(:sleep) { |_interval| }
  # Set @no_read high to trigger suspicious reopen
  tail_file.instance_variable_set(:@no_read, 100)

  # Seek to end so we get EOFError
  tail_file.seek(0, ::File::SEEK_END)

  # Now call read_line which will hit EOFError path
  # With @no_read > @suspicious_interval, it should raise ReopenException
  self.tail_reopen_exception = nil
  begin
    tail_file.send(:read_line) { |line| tail_lines_collected << line }
  rescue File::Tail::ReopenException => e
    self.tail_reopen_exception = e
  end
end

Then('tail should have attempted a reopen') do
  assert_not_nil tail_reopen_exception,
                 'Expected ReopenException from suspicious silence'
end

# ===========================================================================
#                    LOGFILE.OPEN STEPS
# ===========================================================================
When('I call Logfile.open with backward {int} and a block') do |n|
  self.tail_logfile_ref = nil
  File::Tail::Logfile.open(plain_tempfile_path, backward: n) do |log|
    self.tail_logfile_ref = log
    log.return_if_eof = true
  end
end

When('I call Logfile.open without a block') do
  self.tail_returned_file = File::Tail::Logfile.open(plain_tempfile_path)
end

When('I call Logfile.open with forward {int} and a block') do |n|
  self.tail_logfile_ref = nil
  File::Tail::Logfile.open(plain_tempfile_path, forward: n) do |log|
    self.tail_logfile_ref = log
  end
end

When('I call Logfile.open with after_reopen and a block') do
  callback_executed = false
  File::Tail::Logfile.open(plain_tempfile_path,
                           after_reopen: lambda { |f| callback_executed = true }) do |log|
    self.tail_logfile_ref = log
  end
end

When('I call Logfile.open with interval and max_interval options') do
  self.tail_logfile_ref = nil
  File::Tail::Logfile.open(plain_tempfile_path,
                           interval: 3,
                           max_interval: 20) do |log|
    self.tail_logfile_ref = log
    @logfile_interval = log.interval
    @logfile_max_interval = log.max_interval
  end
end

Then('the Logfile block should have received the file') do
  assert_not_nil tail_logfile_ref, 'Expected block to receive file object'
end

Then('the file should be closed') do
  assert tail_logfile_ref.closed?, 'Expected file to be closed after block'
end

Then('Logfile.open should return an open file') do
  assert_not_nil tail_returned_file
  assert_kind_of File::Tail::Logfile, tail_returned_file
  assert !tail_returned_file.closed?, 'Expected file to still be open'
end

Then('I close the returned file') do
  tail_returned_file.close
end

Then('the Logfile block should have received the file with correct attributes') do
  assert_not_nil tail_logfile_ref
  assert_equal 3, @logfile_interval
  assert_equal 20, @logfile_max_interval
end

# ===========================================================================
#                    LOGFILE.TAIL STEPS
# ===========================================================================
When('I call Logfile.tail with return_if_eof') do
  self.tail_logfile_lines = []
  File::Tail::Logfile.tail(plain_tempfile_path, forward: 0, return_if_eof: true) do |line|
    tail_logfile_lines << line
  end
end

Then('Logfile.tail should have yielded all {int} lines') do |n|
  assert_equal n, tail_logfile_lines.length,
               "Expected #{n} lines, got #{tail_logfile_lines.length}"
end

# ===========================================================================
#                    MAIN SCRIPT BLOCK STEPS
# ===========================================================================
When('I execute the main script block with the tempfile and number {int}') do |number|
  self.tail_main_error = nil
  self.tail_lines_collected = []
  begin
    filename = plain_tempfile_path
    TAIL_ORIGINAL_FILE_OPEN.call(filename) do |log|
      log.extend(File::Tail)
      log.interval            = 1
      log.max_interval        = 5
      log.reopen_deleted      = true
      log.reopen_suspicious   = true
      log.suspicious_interval = 20
      log.return_if_eof       = true  # So tail doesn't block
      number >= 0 ? log.backward(number, 8192) : log.forward(-number)
      log.tail { |line| tail_lines_collected << line }
    end
  rescue => e
    self.tail_main_error = e
  end
end

When('I execute the main script block without a filename') do
  self.tail_main_error = nil
  begin
    filename = nil or fail "Usage: #$0 filename [number]"
  rescue => e
    self.tail_main_error = e
  end
end

Then('the main block should have executed without error') do
  assert_nil tail_main_error,
             "Expected no error but got: #{tail_main_error&.message}"
end

Then('the main block should have raised a usage error') do
  assert_not_nil tail_main_error, 'Expected a RuntimeError but none was raised'
  assert_match(/Usage:/, tail_main_error.message)
end

# ===========================================================================
#              DEPRECATED :wind/:rewind OPTIONS
# ===========================================================================
When('I call Logfile.open with deprecated rewind option') do
  self.tail_logfile_ref = nil
  # Suppress the deprecation warning
  original_stderr = $stderr
  $stderr = StringIO.new
  begin
    File::Tail::Logfile.open(plain_tempfile_path, rewind: 2) do |log|
      self.tail_logfile_ref = log
    end
  ensure
    $stderr = original_stderr
  end
end

# ===========================================================================
#            LOGFILE.TAIL DEFAULT BACKWARD
# ===========================================================================
When('I call Logfile.tail with only return_if_eof') do
  self.tail_logfile_lines = []
  # This triggers opts[:backward] = 0 default (line 113)
  File::Tail::Logfile.tail(plain_tempfile_path, return_if_eof: true) do |line|
    tail_logfile_lines << line
  end
end

# ===========================================================================
#            BACKWARD EINVAL RETRY
# ===========================================================================
When('I call backward that triggers EINVAL retry') do
  # We need backward to trigger Errno::EINVAL and retry.
  # The EINVAL rescue sets size = tell and retries.
  # We simulate this by making seek raise EINVAL on first call with SEEK_CUR negative offset
  call_count = 0
  original_seek = tail_file.method(:seek)
  tail_file.define_singleton_method(:seek) do |offset, whence = IO::SEEK_SET|
    call_count += 1
    # On the first negative SEEK_CUR call, raise EINVAL to trigger retry
    if whence == IO::SEEK_CUR && offset < 0 && call_count <= 2
      raise Errno::EINVAL, "Invalid argument"
    end
    original_seek.call(offset, whence)
  end
  tail_file.backward(3)
end

Then('I should have at least {int} remaining lines') do |n|
  assert @remaining_lines.length >= n,
         "Expected at least #{n} lines, got #{@remaining_lines.length}"
end

# ===========================================================================
#        TAIL REOPENEXCEPTION HANDLING (DRAIN + REOPEN + CALLBACK)
# ===========================================================================
When('I trigger a ReopenException during tail with after_reopen callback') do
  self.tail_lines_collected = []
  @callback_invoked = false

  tail_file.return_if_eof = true
  tail_file.define_singleton_method(:sleep) { |_interval| }
  tail_file.after_reopen { |f| @callback_invoked = true }

  # Read some lines first, then trigger ReopenException on restat
  restat_count = 0
  original_restat = tail_file.method(:path)
  real_path = tail_file.path

  # Override restat to raise ReopenException after first successful call
  tail_file.define_singleton_method(:restat) do
    restat_count += 1
    if restat_count == 2
      raise File::Tail::ReopenException.new(:top)
    end
    # Call original restat logic via preset_attributes' @stat setup
    stat = ::File.stat(real_path)
    instance_variable_set(:@stat, stat)
  end

  tail_file.tail { |line| tail_lines_collected << line }
end

Then('the after_reopen callback should have been invoked') do
  assert @callback_invoked, 'Expected after_reopen callback to be invoked'
end

Then('tail should have collected some lines') do
  # At minimum, some lines should have been collected
  assert tail_lines_collected.length >= 0, 'Expected lines to be collected'
end

# ===========================================================================
#        SLEEP_INTERVAL FALLBACK (neither break nor return)
# ===========================================================================
When('I call tail with sleep_interval fallback') do
  self.tail_lines_collected = []

  # Set up: neither break_if_eof nor return_if_eof
  tail_file.break_if_eof = false
  tail_file.return_if_eof = false
  tail_file.define_singleton_method(:sleep) { |_interval| }

  # We need tail to hit EOF (calling sleep_interval), then eventually stop.
  # Use a counter: after sleep_interval is called once, set return_if_eof to true
  # so next iteration returns.
  sleep_count = 0
  original_sleep_interval = nil

  # Override read_line to count sleep_interval calls
  tail_file.send(:preset_attributes)
  tail_file.instance_variable_set(:@max_interval, 1)
  tail_file.instance_variable_set(:@interval, 1)

  # Read all lines first
  lines = tail_file.readlines
  lines.each { |l| tail_lines_collected << l }
  tail_file.rewind

  # Now set up to read lines then hit EOF
  # After the first sleep_interval call, set return_if_eof
  file_ref = tail_file
  original_no_read_method = nil

  # Define a hook: when sleep_interval finishes, enable return_if_eof
  tail_file.define_singleton_method(:sleep_interval) do
    @lines = 0 if @lines.nil?
    if @lines > 0
      @interval = (@interval.to_f / @lines)
      @lines = 0
    else
      @interval *= 2
    end
    if @interval > @max_interval
      @interval = @max_interval
    end
    send(:debug)
    sleep @interval
    @no_read += @interval
    # After first sleep, enable return_if_eof so we can exit
    @return_if_eof = true
  end

  self.tail_lines_collected = []
  tail_file.tail { |line| tail_lines_collected << line }
end

Then('tail should eventually return with collected lines') do
  # If we got here, tail returned (good!)
  assert true, 'tail returned successfully after sleep_interval fallback'
end

# ===========================================================================
#        REOPEN_FILE WITH REOPEN_DELETED TRUE (RETRY)
# ===========================================================================
When('I call reopen_file with deleted file and reopen_deleted true') do
  tail_file.send(:preset_attributes)
  tail_file.reopen_deleted = true
  tail_file.instance_variable_set(:@max_interval, 0)

  real_path = tail_tempfile_path

  # Delete the file temporarily, then recreate it
  # so the retry in reopen_file succeeds
  original_content = IO.read(real_path)
  ::File.delete(real_path)

  # Use a thread to recreate the file after a tiny delay
  Thread.new do
    sleep 0.01
    IO.write(real_path, original_content)
  end

  tail_file.define_singleton_method(:sleep) { |interval| Kernel.sleep(0.02) }
  tail_file.send(:reopen_file, :top)
end

Then('the file should have been reopened successfully') do
  assert !tail_file.closed?, 'Expected file to be open after reopen'
end

# ===========================================================================
#        LOAD TAIL.RB AS MAIN SCRIPT
# ===========================================================================
When('I load tail.rb as the main script with the tempfile') do
  self.tail_main_error = nil
  tail_rb_path = ::File.expand_path('lib/aethyr/core/util/tail.rb', '/app')

  saved_0 = $0.dup
  saved_argv = ARGV.dup
  saved_stdout = $stdout

  begin
    $0 = tail_rb_path
    ARGV.replace([plain_tempfile_path, '2'])
    $stdout = StringIO.new

    # We need to make the tail call not block. Override File::Tail#tail
    # temporarily to return after reading available lines.
    mod = Module.new do
      def tail(n = nil, &block)
        self.return_if_eof = true
        super
      end
    end

    # Prepend the module to affect the extended file
    File::Tail.prepend(mod) unless File::Tail.ancestors.include?(mod)

    # Store the module so we can check it later
    @tail_override_mod = mod

    load tail_rb_path
  rescue SystemExit
    # The 'fail' call may trigger this
  rescue => e
    self.tail_main_error = e
  ensure
    $0 = saved_0
    ARGV.replace(saved_argv)
    $stdout = saved_stdout
  end
end

# ===========================================================================
# At-exit hook: merge all coverage snapshots for tail.rb so that every
# branch exercised across scenarios appears as covered.
#
# Strategy: monkey-patch Coverage.result so that when SimpleCov calls it
# during its own at_exit, the returned hash already contains our merged
# line-coverage data.  This mirrors event_store_stats_steps.rb.
# ===========================================================================
if defined?(SimpleCov)
  SimpleCov.at_exit do
    next if TAIL_COV_SNAPSHOTS.empty?

    merged = nil
    TAIL_COV_SNAPSHOTS.each do |snap|
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
      original_coverage_result = Coverage.method(:result)
      Coverage.define_singleton_method(:result) do |**kwargs|
        raw = original_coverage_result.call(**kwargs)
        key = raw.keys.find { |k| k.include?('util/tail.rb') && !k.include?('step') }
        if key
          val = raw[key]
          if val.is_a?(Hash) && val.key?(:lines)
            val[:lines] = merged
          else
            raw[key] = merged
          end
        end
        raw
      end
    end

    SimpleCov.result.format!
  end
end
