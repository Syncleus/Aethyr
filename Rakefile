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
    Coverage::RakeTask.new(:integration, cucumber_task: :integration_nocov, coverage_dir: COVERAGE_INTEGRATION) # the TaskLib defines the :coverage command
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
# rubocop:enable Style/Documentation

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

