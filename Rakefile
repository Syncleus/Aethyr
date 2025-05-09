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

# Project-local task libraries.
safe_require_relative 'lib/aethyr/core/util/config'
safe_require_relative 'features/support/coverage/rake_task'

# -----------------------------------------------------------------------------
#  Constants – grouped to prevent top-level namespace pollution.
# -----------------------------------------------------------------------------
module BuildConstants
  CUKE_RESULTS = 'results.html'
end

# -----------------------------------------------------------------------------
#  Task Builders – one class per autonomous concern (SRP).
# -----------------------------------------------------------------------------

# rubocop:disable Style/Documentation
class TestTaskBuilder
  include Rake::DSL            # Prefer composition over inheritance.

  # Public: Install a `:test` task backed by Rake::TestTask.
  #
  # pattern - Glob pattern describing test files (default: 'test/tc_*.rb').
  #
  # Returns nothing.
  def install(pattern: 'test/tc_*.rb')
    Rake::TestTask.new(:test) do |t|
      t.pattern = pattern
    end
  end
end

class FeaturesTaskBuilder
  include Rake::DSL
  include BuildConstants

  # Public: Install a Cucumber task that generates both pretty and HTML output.
  def install
    CLEAN << CUKE_RESULTS # established by rake/clean

    Cucumber::Rake::Task.new(:features) do |t|
      # --format pretty : human-readable terminal output
      # --format html   : machine-consumable report persisted to disk
      # --no-source     : omits feature file listings for brevity
      # -x              : fail fast on first error to save CI cycles
      t.cucumber_opts = [
        'features',
        '--format', 'html', '-o', CUKE_RESULTS,
        '--format', 'pretty', '--no-source', '-x'
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

class CoverageTaskBuilder
  include Rake::DSL

  # Public: Attach the :coverage task implemented by Coverage::RakeTask.
  def install
    Coverage::RakeTask.new # the TaskLib defines the :coverage command
  end
end

class IntegrationTaskBuilder
  include Rake::DSL
  include BuildConstants

  RESULTS_FILE = 'integration_results.html'

  # Public: Install a dedicated Cucumber task for integration testing.
  # Separate artefacts ensure unit and integration phases do not overlap.
  def install
    CLEAN << RESULTS_FILE

    # Signal integration coverage upfront so the environment is inherited by
    # the Cucumber process. The rake process is the parent of the Cucumber
    # runner therefore this single assignment suffices.
    ENV['AETHYR_COVERAGE_INTEGRATION'] = '1'

    Cucumber::Rake::Task.new(:integration) do |t|
      # Direct Cucumber to the *integration* feature directory only.
      t.cucumber_opts = [
        '--require', 'integration',
        'integration',
        '--format', 'html', '-o', RESULTS_FILE,
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
    TestTaskBuilder.new.install
    FeaturesTaskBuilder.new.install
    DocsTaskBuilder.new.install
    CoverageTaskBuilder.new.install
    IntegrationTaskBuilder.new.install

    desc 'Run unit tests and cucumber features (default)'
    task default: %i[test features]

    # Delegate gem-packaging related tasks to Bundler (e.g. `rake release`).
    Bundler::GemHelper.install_tasks
  end
end

# -----------------------------------------------------------------------------
#  Execution entry point – kick the whole thing off.
# -----------------------------------------------------------------------------
Build.install

