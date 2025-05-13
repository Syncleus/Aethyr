# ConsoleReporter
# frozen_string_literal: true

# =============================================================================
#  Module: Coverage
# -----------------------------------------------------------------------------
#  Ruby already ships with a `Coverage` module from the standard library.  
#  Re-opening that module is entirely safe and *adds* behaviour without
#  clobbering the built-in API. By doing so we keep all coverage-related code
#  discoverable in a single namespace while avoiding the introduction of a
#  new top-level constant.
# =============================================================================
module Coverage
  # ===========================================================================
  #  Class: ConsoleReporter
  # ---------------------------------------------------------------------------
  #  A façade around SimpleCov that encapsulates *all* decisions about:
  #
  #    • which formatter to use
  #    • which directories/files should be ignored
  #    • what minimum coverage threshold must be met
  #
  #  The class purposefully exposes **one** public entry-point (`install!`) so
  #  the rest of the application does **not** depend on SimpleCov's rich API.
  #
  #  SOLID design-notes:
  #
  #  • SRP – the class' only responsibility is *bootstrapping* SimpleCov.  
  #  • OCP – callers can swap formatter / filters / threshold without edits.  
  #  • LSP – `ConsoleReporter` can be replaced by any object responding to
  #           `install!` (e.g. for tests).  
  #  • ISP – the public interface is minimal (`install!` only).  
  #  • DIP – depends on abstractions (formatter duck-type), not concrete HTML
  #           or console formatters.
  #
  #  Patterns employed:
  #    1. Builder  – step-by-step configuration of SimpleCov.
  #    2. Facade   – hides SimpleCov complexity behind a single call.
  # ===========================================================================
  class ConsoleReporter
    # ------------------------------------------------------------------------
    #  FACTORY METHOD
    # ------------------------------------------------------------------------
    # Public API.  One-shot helper that hides object construction and keeps the
    # call-site tidy.
    #
    # @param formatter    [Class<#format>] Anything that quacks like a
    #                                          SimpleCov formatter.
    # @param filters      [Array<String>]   Path prefixes to exclude.
    # @param minimum_cov  [Float]           Fail build if overall coverage
    #                                       drops below this percentage.
    # @param track_files  [String|Array]    Files to track even if not required.
    #
    # @return [void]
    #
    # @example Using all defaults
    #   Coverage::ConsoleReporter.install!
    #
    # @example Custom threshold & custom filter
    #   Coverage::ConsoleReporter.install!(
    #     minimum_cov: 95,
    #     filters: ['/spec/', '/test/', '/vendor/']
    #   )
    #
    def self.install!(formatter:    SimpleCov::Formatter::Console,
                      filters:      %w[/spec/ /test/],
                      minimum_cov:  85.0,
                      track_files:  'lib/**/*.rb')
      new(formatter, filters, minimum_cov, track_files).install
    end

    # ------------------------------------------------------------------------
    #  CONSTRUCTOR
    # ------------------------------------------------------------------------
    # rubocop:disable Metrics/ParameterLists
    def initialize(formatter, filters, minimum_cov, track_files)
      @formatter     = formatter
      @filters       = filters
      @minimum_cov   = minimum_cov
      @track_files   = Array(track_files)
    end
    # rubocop:enable Metrics/ParameterLists

    # ------------------------------------------------------------------------
    #  INSTANCE BEHAVIOUR
    # ------------------------------------------------------------------------
    # Bootstraps SimpleCov.  Must be invoked *before* the application requires
    # any of its own files – typically at Rake-task invocation time.
    #
    # @return [void]
    def install
      # -- 1. Lazy-load dependencies -------------------------------------------------
      require 'simplecov'           # main gem
      require 'simplecov-console'   # ANSI colour formatter (used by default)
      require 'simplecov-html'       # ensures HTML formatter
      require_relative 'plain_text_formatter'        # NEW

      # --------------------------------------------------------------------
      # 1. Build our formatter *stack* (pass CLASSES – MultiFormatter will
      #    instantiate them for every run)
      # --------------------------------------------------------------------
      formatter_stack = [
        @formatter,                           # colourised console output  – already a class
        SimpleCov::Formatter::HTMLFormatter,  # full HTML report
        Coverage::PlainTextFormatter          # plain-text file formatter  – CLASS, not instance
      ]

      SimpleCov.formatter =
        SimpleCov::Formatter::MultiFormatter.new(formatter_stack)

      # --------------------------------------------------------------------
      # 2. Standard SimpleCov configuration (unchanged)
      # --------------------------------------------------------------------
      SimpleCov.start do
        # Respect task-specific coverage thresholds supplied by the Rake
        # wrapper – this must be declared *inside* the configuration block so
        # that SimpleCov anchors the value to the current result set instead
        # of the global default.  Placing the directive earlier (before the
        # `start` invocation) causes subsequent `SimpleCov.start` calls from
        # other tasks to overwrite the value – manifesting as the hard-coded
        # 85 % failure we observed during the integration test run.
        minimum_coverage @minimum_cov

        # Exclude noise
        @filters.each { |path| add_filter(path) }

        # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        # The crucial line – ensure files that never get `require`d still appear
        # in the report with 0 % coverage.
        # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        @track_files.each   { |glob| track_files(glob) }
      end
    end
    # ------------------------------------------------------------------------
    #  END OF INSTANCE BEHAVIOUR
  end
end 