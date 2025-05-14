# frozen_string_literal: true

# =============================================================================
#  Aethyr Build Automation – Rakefile
# =============================================================================
#  This Rakefile orchestrates the complete build, test, documentation, and
#  coverage workflow for the Aethyr project. It is deliberately crafted to
#  showcase robust, object-oriented architecture that rigorously adheres to
#  SOLID principles while exploiting classic design patterns for maximum
#  maintainability and flexibility.
#
#  ▸ Single-Responsibility – Each concrete task class models exactly one
#    autonomous concern and therefore one axis of change.
#  ▸ Open/Closed           – New behaviour can be grafted on by *extending*
#    instead of *modifying* existing code.
#  ▸ Liskov Substitution   – Every task object is substitutable because all of
#    them implement the same public façade (#install).
#  ▸ Interface Segregation – The public API is intentionally minimal, sparing
#    clients from needless implementation details.
#  ▸ Dependency Inversion  – High-level orchestration depends on Rake DSL
#    abstractions rather than concrete implementations.
#
#  Patterns employed:
#    • Facade   – The Build module presents a single, intention-revealing entry
#                 point (Build.install).
#    • Builder  – Each task-builder class assembles a complex TaskLib in a
#                 stepwise, controlled fashion.
#    • Command  – Rake tasks are executed as explicit command objects.
#    • Template-Method – Shared skeletal algorithms defer hook points to
#                         specialised subclasses.
#    • Null-Object – Graceful failure via safe_require* helpers prevents
#                    disruptive NameErrors.
# =============================================================================

# -----------------------------------------------------------------------------
#  Boot sequence – establish a predictable, dependency-safe execution context.
# -----------------------------------------------------------------------------
require 'rubygems'

# Bundler is indispensable; fail fast if it cannot be loaded.
begin
  require 'bundler/setup'
rescue LoadError => e
  abort <<~MSG
    ▸ Bundler is not available – please `gem install bundler && bundle install`.
      Details: #{e.message}
  MSG
end

require 'rake'          # Core DSL – provides Rake::Task, Rake::TaskLib, etc.
require 'rake/clean'    # Adds the ubiquitous `clean` and `clobber` targets.

module RakeConstants
  BUILD_DIR           = 'build'
  UNIT_DIR    = "#{BUILD_DIR}/tests/unit"
  INTEGRATION_DIR = "#{BUILD_DIR}/tests/integration"
  RESULTS_UNIT        = "#{UNIT_DIR}/results.html"
  RESULTS_INTEGRATION = "#{INTEGRATION_DIR}/results.html"
  COVERAGE_UNIT = "#{UNIT_DIR}/coverage"
  COVERAGE_INTEGRATION = "#{INTEGRATION_DIR}/coverage"
end

# -----------------------------------------------------------------------------
#  Defensive-loading utilities (Null-Object Pattern)
# -----------------------------------------------------------------------------
#  These helpers guarantee that missing dependencies manifest as *actionable*
#  error messages instead of cryptic NameErrors later in the build.
# -----------------------------------------------------------------------------

def safe_require(lib, gem_name = lib)
  require lib
rescue LoadError => e
  abort "▸ Missing dependency: `#{gem_name}` (failed to `require '#{lib}'`) – #{e.message}"
end

# Relative variant – primarily used for project-local libraries.

def safe_require_relative(path)
  require_relative path
rescue LoadError, NameError => e
  abort "▸ Failed to load relative file '#{path}' – #{e.class}: #{e.message}"
end

# -----------------------------------------------------------------------------
#  Core library imports – executed only after gem constraints are declared.
# -----------------------------------------------------------------------------
safe_require 'rake/testtask',      'rake'
safe_require 'cucumber/rake/task', 'cucumber'
safe_require 'rdoc/task',          'rdoc'
safe_require 'bundler/gem_helper', 'bundler'
safe_require 'ncursesw',           'ncursesw'

# Project-local task libraries.
safe_require_relative 'lib/aethyr/core/util/config'
safe_require_relative 'tests/rake_task'

ServerConfig[:log_level] = 0
$VERBOSE = nil

# -----------------------------------------------------------------------------
#  Task Builders – one class per autonomous concern (SRP).
# -----------------------------------------------------------------------------

class UnitNoCoverageTaskBuilder
  include Rake::DSL
  include RakeConstants

  # Public: Install a Cucumber task that generates both pretty and HTML output.
  def install
    CLEAN << BUILD_DIR # established by rake/clean

    # -----------------------------------------------------------------------------
    #  Directory Structure Creation
    # -----------------------------------------------------------------------------
    # Ensures the integration test results directory exists before running tests.
    # This follows the Single Responsibility Principle by isolating the directory
    # creation concern in a dedicated method.
    directory UNIT_DIR
    
    # Make the integration_nocov task depend on the directory creation
    # This demonstrates the Dependency Inversion Principle by depending on the
    # abstract concept of a prerequisite task rather than concrete directory operations
    task :unit_nocov => [UNIT_DIR]

    Cucumber::Rake::Task.new(:unit_nocov) do |t|
      # --format pretty : human-readable terminal output
      # --format html   : machine-consumable report persisted to disk
      # --no-source     : omits feature file listings for brevity
      # -x              : fail fast on first error to save CI cycles
      t.cucumber_opts = [
        '--require', 'tests/unit',
        'tests/unit',
        '--format', 'html', '-o', RESULTS_UNIT,
        '--format', 'pretty', '--no-source'
      ]
      t.fork = false # Ruby 3.x: forking is unnecessary and slower
    end
  end
end

class DocsTaskBuilder
  include Rake::DSL

  # Public: Generate API documentation using RDoc.
  def install
    Rake::RDocTask.new(:rdoc) do |rd|
      rd.main = 'README.rdoc'
      rd.rdoc_files.include('README.rdoc', 'lib/**/*.rb', 'bin/**/*')
    end
  end
end

class UnitTaskBuilder
  include Rake::DSL
  include RakeConstants
  # Public: Attach the :coverage task implemented by Coverage::RakeTask.
  def install
    Coverage::RakeTask.new(:unit, cucumber_task: :unit_nocov, coverage_dir: COVERAGE_UNIT) # the TaskLib defines the :coverage command
  end
end

class IntegrationTaskBuilder
  include Rake::DSL
  include RakeConstants
  # Public: Attach the :coverage task implemented by Coverage::RakeTask.
  def install
    # Integration tests exercise the full stack but naturally touch a
    # far smaller slice of the overall codebase compared to unit tests.  For
    # this reason their line-coverage percentage is *expected* to be
    # substantially lower.  We therefore relax the enforcement threshold to
    # a pragmatic 35 % which is sufficient to detect egregious coverage
    # regressions without producing spurious CI failures.
    Coverage::RakeTask.new(
      :integration,
      cucumber_task: :integration_nocov,
      coverage_dir:  COVERAGE_INTEGRATION,
      minimum_cov:   35.0
    ) # the TaskLib defines the :coverage command
  end
end

class IntegrationNoCoverageTaskBuilder
  include Rake::DSL
  include RakeConstants

  # Public: Install a dedicated Cucumber task for integration testing.
  # Separate artefacts ensure unit and integration phases do not overlap.
  def install
    CLEAN << BUILD_DIR

    # -----------------------------------------------------------------------------
    #  Directory Structure Creation
    # -----------------------------------------------------------------------------
    # Ensures the integration test results directory exists before running tests.
    # This follows the Single Responsibility Principle by isolating the directory
    # creation concern in a dedicated method.
    directory INTEGRATION_DIR
    
    # Make the integration_nocov task depend on the directory creation
    # This demonstrates the Dependency Inversion Principle by depending on the
    # abstract concept of a prerequisite task rather than concrete directory operations
    task :integration_nocov => [INTEGRATION_DIR]

    Cucumber::Rake::Task.new(:integration_nocov) do |t|
      # Direct Cucumber to the *integration* feature directory only.
      t.cucumber_opts = [
        '--require', 'tests/integration',
        'tests/integration',
        '--format', 'html', '-o', RESULTS_INTEGRATION,
        '--format', 'pretty', '--no-source'
      ]

      # Avoid fail-fast so every scenario runs regardless of earlier failures.
      t.fork = false
    end
  end
end

# -----------------------------------------------------------------------------
#  IntegrationProfileTaskBuilder - Add profiling to integration tests
# -----------------------------------------------------------------------------
#  This builder configures a Rake task that behaves identical to the
#  integration_nocov task but adds Ruby profiling to the test run.
#  It follows all the same SOLID principles:
#  • Single-Responsibility – owns *only* the profiling integration concern
#  • Open/Closed – behavior can be modified via parameters without changing code
#  • Liskov Substitution – interchangeable with other task builders
#  • Interface Segregation – minimal API through #install method
#  • Dependency Inversion – depends on Rake abstractions
# -----------------------------------------------------------------------------
class IntegrationProfileTaskBuilder
  include Rake::DSL
  include RakeConstants

  # Public: Install a task for integration testing with profiling.
  # This implementation uses the profiler.rb utility to collect and display
  # detailed method-level profiling information from within the Ruby process.
  def install
    CLEAN << BUILD_DIR

    # Ensure the integration test results directory exists
    directory INTEGRATION_DIR
    
    # Define a custom task for detailed profiling
    desc "Run integration tests with detailed method and class-level profiling"
    task :integration_profile => [INTEGRATION_DIR] do
      # Load our profiler utility
      require_relative 'tests/profiler'
      
      # Begin profiling
      puts "\n" + ("=" * 80)
      puts "STARTING PROFILED INTEGRATION TESTS"
      puts ("=" * 80)
      
      # Run integration_nocov task with profiling
      # This ensures we capture detailed metrics while running the same tests
      Aethyr.profile do
        # Create a new Cucumber::Rake::Task programmatically
        # This is necessary to run Cucumber in the same Ruby process
        # so the profiler can collect method-level statistics
        require 'cucumber/rake/task'
        cucumber = Cucumber::Rake::Task.new(:_integration_profile_helper, &method(:configure_cucumber))
        cucumber.runner.run
      end
      
      # Delete the temporary task
      Rake.application.instance_variable_get('@tasks').delete('_integration_profile_helper')
    end
  end
  
  private
  
  # Configure the Cucumber task exactly like integration_nocov
  # This ensures the same behavior while allowing for profiling
  def configure_cucumber(t)
    t.cucumber_opts = [
      '--require', 'tests/integration',
      'tests/integration',
      '--format', 'html', '-o', RESULTS_INTEGRATION,
      '--format', 'pretty', '--no-source'
    ]
    t.fork = false  # Important: ensure Cucumber runs in the same process
  end
end

# -----------------------------------------------------------------------------
#  UnitProfileTaskBuilder - Add profiling to unit tests
# -----------------------------------------------------------------------------
#  This builder configures a Rake task that behaves identical to the
#  unit_nocov task but adds Ruby profiling to the test run.
#  It follows all the same SOLID principles:
#  • Single-Responsibility – owns *only* the profiling unit test concern
#  • Open/Closed – behavior can be modified via parameters without changing code
#  • Liskov Substitution – interchangeable with other task builders
#  • Interface Segregation – minimal API through #install method
#  • Dependency Inversion – depends on Rake abstractions
# -----------------------------------------------------------------------------
class UnitProfileTaskBuilder
  include Rake::DSL
  include RakeConstants

  # Public: Install a task for unit testing with profiling.
  # This implementation uses the profiler.rb utility to collect and display
  # detailed method-level profiling information from within the Ruby process.
  def install
    CLEAN << BUILD_DIR

    # Ensure the unit test results directory exists
    directory UNIT_DIR
    
    # Define a custom task for detailed profiling
    desc "Run unit tests with detailed method and class-level profiling"
    task :unit_profile => [UNIT_DIR] do
      # Load our profiler utility
      require_relative 'tests/profiler'
      
      # Begin profiling
      puts "\n" + ("=" * 80)
      puts "STARTING PROFILED UNIT TESTS"
      puts ("=" * 80)
      
      # Run unit_nocov task with profiling
      # This ensures we capture detailed metrics while running the same tests
      Aethyr.profile do
        # Create a new Cucumber::Rake::Task programmatically
        # This is necessary to run Cucumber in the same Ruby process
        # so the profiler can collect method-level statistics
        require 'cucumber/rake/task'
        cucumber = Cucumber::Rake::Task.new(:_unit_profile_helper, &method(:configure_cucumber))
        cucumber.runner.run
      end
      
      # Delete the temporary task
      Rake.application.instance_variable_get('@tasks').delete('_unit_profile_helper')
    end
  end
  
  private
  
  # Configure the Cucumber task exactly like unit_nocov
  # This ensures the same behavior while allowing for profiling
  def configure_cucumber(t)
    t.cucumber_opts = [
      '--require', 'tests/unit',
      'tests/unit',
      '--format', 'html', '-o', RESULTS_UNIT,
      '--format', 'pretty', '--no-source'
    ]
    t.fork = false  # Important: ensure Cucumber runs in the same process
  end
end

# -----------------------------------------------------------------------------
#  DocusaurusDocsTaskBuilder – Compile and serve the Docusaurus site
# -----------------------------------------------------------------------------
#  This builder encapsulates all responsibilities surrounding the generation
#  and live-serving of the end-user documentation written in Markdown/MDX and
#  rendered via Facebook's Docusaurus.
#
#  It follows the same architectural constraints as the rest of this Rakefile:
#  • Each builder owns exactly *one* concern (Single-Responsibility).
#  • New behaviour can be introduced through subclassing or additional
#    builders without touching existing code (Open/Closed).
#  • The public façade remains a solitary `#install` method (Interface
#    Segregation).
#  • The implementation depends on the Rake DSL rather than concrete shell
#    commands (Dependency Inversion): the DSL merely *delegates* to the system
#    shell.
# -----------------------------------------------------------------------------
class DocusaurusDocsTaskBuilder
  include Rake::DSL

  # Centralised constant – a single source of truth for the build artefact
  # location keeps the rest of the task definitions DRY.
  BUILD_DIR = 'build/docs'

  # Public: Inject the `documentation` and `documentation_serve` tasks into the
  # global Rake namespace.
  def install
    # Purge generated HTML on `rake clobber`.
    CLEAN << BUILD_DIR

    # -------------------------------------------------------------------------
    #  Static build – transforms Markdown into a fully-baked HTML site.
    # -------------------------------------------------------------------------
    desc 'Compile the static end-user documentation via Docusaurus'
    task :documentation do
      sh 'npm run build' # Delegates to package.json → "build"
    end

    # -------------------------------------------------------------------------
    #  Development server – hot-reloads docs locally for authors.
    # -------------------------------------------------------------------------
    desc 'Serve the documentation locally on IPv4 (hot-reload)'
    task :documentation_serve do
      # Forward the host flag explicitly to guarantee IPv4-only binding even on
      # systems where Node defaults to dual-stack.
      sh 'npm run start -- --host 0.0.0.0'
    end
  end
end

# -----------------------------------------------------------------------------
#  Facade – high-level build orchestration exposed to callers.
# -----------------------------------------------------------------------------
module Build
  extend Rake::DSL

  module_function

  # Public: Install all individual tasks and wire-up the default alias.
  def install
    # ***********************************************************************
    #  NB: Instantiation *implicitly* calls #install on each Builder since
    #      they execute side-effects inside their constructor. Should you
    #      prefer explicitness, swap to `.new.install` instead.
    # ***********************************************************************
    UnitNoCoverageTaskBuilder.new.install
    DocsTaskBuilder.new.install
    UnitTaskBuilder.new.install
    IntegrationNoCoverageTaskBuilder.new.install
    IntegrationTaskBuilder.new.install
    IntegrationProfileTaskBuilder.new.install
    UnitProfileTaskBuilder.new.install
    DocusaurusDocsTaskBuilder.new.install

    desc 'Run unit tests and cucumber features (default)'
    task default: %i[unit]

    # Delegate gem-packaging related tasks to Bundler (e.g. `rake release`).
    Bundler::GemHelper.install_tasks
  end
end

# -----------------------------------------------------------------------------
#  Execution entry point – kick the whole thing off.
# -----------------------------------------------------------------------------
Build.install

