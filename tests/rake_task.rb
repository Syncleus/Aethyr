# frozen_string_literal: true

# =============================================================================
#  Coverage::RakeTask
# -----------------------------------------------------------------------------
#  A SOLID, SRP-compliant wrapper that plugs SimpleCov's console formatter into
#  your build without forcing callers to learn the SimpleCov API.
#
#  • Single-Responsibility – owns *only* the Rake integration concern.
#  • Open/Closed           – behaviour can be tweaked via public setters /
#                             constructor block; no modification required.
#  • Liskov Substitution   – interchangeable with any other Rake::TaskLib.
#  • Interface Segregation – exposes the minimal surface needed by Rakefiles:
#                              `Coverage::RakeTask.new { … }`
#  • Dependency Inversion  – depends on SimpleCov abstractions, not concrete
#                             formatters.
#
#  Patterns:
#    • Facade   – hides SimpleCov's rich API behind a tiny, intention-revealing
#                 domain-specific façade.
#    • Command  – encapsulates "run tests + gather coverage" as an executable
#                 object (the Rake task).
# =============================================================================
require 'rake'
require 'rake/tasklib'
require_relative 'console_reporter'
require 'simplecov'
require 'simplecov-console'

module Coverage
  # Public: Attach a `:coverage` task that runs all tests + Cucumber features
  #         under SimpleCov and prints a rich, colourised summary on exit.
  #
  # @example
  #   require 'coverage/rake_task'
  #   Coverage::RakeTask.new                    # defines task :coverage
  #
  #   # Customise:
  #   Coverage::RakeTask.new(minimum_cov: 95) do |t|
  #     t.test_task     = :spec        # run RSpec suite instead of Test::Unit
  #     t.cucumber_task = :features    # (default) run cucumber afterwards
  #   end
  class RakeTask < ::Rake::TaskLib
    # --------------------------------------------------------------------------
    #  Public API (Open for extension)
    # --------------------------------------------------------------------------
    attr_accessor :name,           # Symbol – Rake task name
                  :test_task,      # Symbol – prerequisite test task
                  :cucumber_task,  # Symbol – prerequisite cucumber task
                  :formatter,      # Class  – SimpleCov formatter
                  :filters,        # Array<String> – path prefixes to ignore
                  :minimum_cov     # Numeric – % threshold that fails CI

    # rubocop:disable Metrics/ParameterLists
    def initialize(name = :unit,
                   cucumber_task: :unit_nocov,
                   formatter:     SimpleCov::Formatter::Console,
                   filters:       %w[/spec/],
                   minimum_cov:   85.0,
                   coverage_dir:  'build/tests/unit/coverage') # rubocop:enable Metrics/ParameterLists
      # Assign each instance variable individually for better readability and maintainability
      @name = name.to_sym                # The name of the Rake task to be created
      @cucumber_task = cucumber_task.to_sym  # The prerequisite cucumber task that will be invoked
      @formatter = formatter             # The SimpleCov formatter to use for reporting
      @filters = filters                 # Path prefixes to ignore in coverage calculations
      @minimum_cov = minimum_cov         # Minimum coverage percentage threshold for CI passing
      @coverage_dir = coverage_dir       # The directory to store coverage reports
      yield self if block_given? # allow caller DSL-style overrides
      define
    end

    private

    # --------------------------------------------------------------------------
    #  Template-Method – steps required to *define* and wire-up the task.
    # --------------------------------------------------------------------------
    def define
      desc 'Run all tests & features with console-based coverage reporting'
      task @name do
        # Install SimpleCov *before* any application code is required.
        ConsoleReporter.install!(
          formatter:    @formatter,
          filters:      @filters,
          minimum_cov:  @minimum_cov
        )

        SimpleCov.coverage_dir(@coverage_dir) if defined?(SimpleCov)

        invoke_task(@cucumber_task)
      end
    end

    # Helper – gracefully invoke prerequisite tasks only if they exist.
    def invoke_task(task_name)
      return unless ::Rake::Task.task_defined?(task_name)

      ::Rake::Task[task_name].invoke
    end
  end
end 