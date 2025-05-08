# frozen_string_literal: true

require "optparse"
require "ostruct"
require "aethyr/experiments/runner"

module Aethyr
  module Experiments
    # ----------------------------------------------------------------------------
    # Class: Aethyr::Experiments::CLI
    #
    # Provides a Paper-Thin façade over OptionParser to translate
    # command-line arguments into a Ruby data-structure understood by
    # Runner.  Maintains SRP by delegating *all* core behaviour to
    # Runner (Strategy pattern: CLI merely selects a concrete strategy
    # at runtime).
    # ----------------------------------------------------------------------------
    class CLI
      # Public: Parses command-line arguments and launches a Runner.
      #
      # +argv+ – Enumerable list of command-line tokens (typically ARGV).
      #
      # Returns nothing – exit status bubbles out of Runner.
      def self.start(argv)
        options = OpenStruct.new(
          script:  nil,
          player:  "TestSubject",
          attach:  false,
          verbose: false
        )

        parser = OptionParser.new do |o|
          o.banner = "Usage: aethyr_experiments [options] my_script.rb"

          o.on("-p", "--player NAME", "Name of the sandbox player (default: TestSubject)") do |v|
            options.player = v
          end

          o.on("-a", "--attach", "Attach to a running server instead of spawning one") do
            options.attach = true
          end

          o.on("-v", "--[no-]verbose", "Verbose output (diagnostics & debug info)") do |v|
            options.verbose = v
          end

          o.on("-h", "--help", "Show this help") do
            puts o
            exit
          end
        end

        # Stop parsing at first non-option (→ experiment script path)
        script_path = parser.parse!(argv).first
        unless script_path
          warn "ERROR: Please supply a Ruby experiment script.\n\n#{parser}"
          exit 1
        end
        options.script = script_path

        Runner.new(options).execute
      rescue OptionParser::InvalidOption => e
        warn e.message
        warn parser
        exit 1
      end
    end
  end
end 