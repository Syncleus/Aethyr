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
    config.exit_timeout = 20     # seconds to wait for spawned processes to exit
    config.io_wait_timeout = 10  # I/O readiness grace period
  end
end
  
After do
  # Ensure RUBYLIB is restored to avoid cross-test contamination.
  ENV['RUBYLIB'] = @original_rubylib

  # Kill *all* processes started by Aruba for deterministic teardown, even if
  # a scenario failed midway.
  stop_all_commands
end 