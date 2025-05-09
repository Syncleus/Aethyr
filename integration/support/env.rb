# frozen_string_literal: true

# -----------------------------------------------------------------------------
#  Integration Test Environment Bootstrap
# -----------------------------------------------------------------------------
#  This file is automatically required by Cucumber for every integration run
#  (because it resides under integration/support).  The goal is to insulate the
#  integration layer from the unit-test environment whilst re-using as much of
#  the existing helper infrastructure as possible.
# -----------------------------------------------------------------------------

require 'aruba/cucumber'           # CLI/process orchestration utilities
require 'methadone/cucumber'       # Consistent CLI world helpers
require 'test/unit/assertions'     # Assertion mix-in for step definitions
require 'socket'                   # TCP client connections to the Aethyr server

# -----------------------------------------------------------------------------
#  Code-coverage (SimpleCov)
# -----------------------------------------------------------------------------
#  Integration coverage is kept strictly separate from unit coverage so that
#  feedback remains focused and easy to interpret. The environment variable is
#  set by the Rake task (see IntegrationTaskBuilder).
# -----------------------------------------------------------------------------
if ENV['AETHYR_COVERAGE_INTEGRATION'] && !defined?(SimpleCov)
  require 'coverage/console_reporter'
  # Re-use the existing façade but override the output directory so the two
  # coverage phases never overwrite each other.
  Coverage::ConsoleReporter.install!
  SimpleCov.coverage_dir('coverage/integration') if defined?(SimpleCov)
end

# -----------------------------------------------------------------------------
#  PATH & LOAD-PATH adjustments – mirror the unit-test setup so the executable
#  under test and project libraries are discoverable.
# -----------------------------------------------------------------------------
ENV['PATH']   = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}" \
              "#{File::PATH_SEPARATOR}#{ENV.fetch('PATH', '')}"
LIB_DIR       = File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib')

Before do
  # Store original RUBYLIB so we can restore it afterwards (isolation!)
  @original_rubylib = ENV['RUBYLIB']
  ENV['RUBYLIB'] = [LIB_DIR, ENV['RUBYLIB']].compact.join(File::PATH_SEPARATOR)

  # Aruba: keep command output available for debugging but do not flood CI
  @puts = true

  # Aruba timeouts – integration scenarios need a little more leeway because
  # the server must boot before the first assertion can execute.
  Aruba.configure do |config|
    config.exit_timeout = 10     # seconds to wait for spawned processes to exit
    config.io_wait_timeout = 5   # I/O readiness grace period
  end
end

After do
  # Ensure RUBYLIB is restored to avoid cross-test contamination.
  ENV['RUBYLIB'] = @original_rubylib

  # Kill *all* processes started by Aruba for deterministic teardown, even if
  # a scenario failed midway.
  stop_processes!
end 