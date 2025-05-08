# frozen_string_literal: true

# =============================================================================
#  Coverage::PlainTextFormatter
# -----------------------------------------------------------------------------
#  A minimalist SimpleCov formatter that writes a concise, plain-text summary
#  to disk so that CI systems (or humans skimming a log file) can read coverage
#  results without an ANSI-aware console or a browser.
#
#  Design notes
#    • SRP   – owns *only* the "render to text-file" concern.
#    • OCP   – pluggable via SimpleCov's formatter API.
#    • LSP   – fully quacks like any other SimpleCov formatter (#format).
#    • ISP   – single-method public interface (#format).
#    • DIP   – depends on SimpleCov abstractions, nothing else.
#
#  Pattern employed
#    • Strategy – interchangeable 'reporting strategy' used by a MultiFormatter.
# =============================================================================
require 'fileutils'
require 'simplecov'

module Coverage
  # --------------------------------------------------------------------------
  # PlainTextFormatter
  # --------------------------------------------------------------------------
  # Writes a concise, human-readable coverage summary to
  #   <coverage_path>/coverage.txt
  #
  # NOTE:
  #   • SimpleCov ≥ 0.22 invokes `#format` with *two* arguments
  #     ( result, original_result ); previous versions only passed `result`.
  #   • To remain compatible with both APIs we leave the first positional
  #     parameter (`result`) untouched and silently ignore anything that
  #     follows via a splat.
  # --------------------------------------------------------------------------
  class PlainTextFormatter
    # -----------------------------------------------------------------------
    # Public API – called by SimpleCov::Formatter::MultiFormatter
    # -----------------------------------------------------------------------
    # NOTE: SimpleCov ≥ 0.22 passes two arguments to #format. We accept *all*
    #       extras via the splat to remain forward-compatible.
    #
    # @param result       [SimpleCov::Result] coverage data for the run
    # @param *_ignore_me  [Array]             (ignored – future proofing)
    # @return             [String] absolute path to the generated report
    def format(result, *_ignore_me)
      output_dir  = SimpleCov.coverage_path
      output_file = File.join(output_dir, 'coverage.txt')

      FileUtils.mkdir_p(output_dir)
      File.write(output_file, ReportBuilder.new(result).to_s)

      puts "Plain-text coverage report written to: #{output_file}"
      output_file
    end

    # -----------------------------------------------------------------------
    # Internal helper objects
    # -----------------------------------------------------------------------
    class ReportBuilder
      # @param result [SimpleCov::Result]
      def initialize(result)
        @result = result
      end

      # Constructs the entire multi-section report.
      #
      # @return [String]
      def to_s
        lines = []
        lines << overall_header
        lines << group_table
        lines << file_details
        lines.join("\n")
      end

      private

      # ----------------------------------------------------
      # Section 1 – Overall coverage
      # ----------------------------------------------------
      def overall_header
        overall = format('%.2f', @result.covered_percent)
        [
          horizontal_rule(' OVERALL COVERAGE '),
          "Total   : #{overall}% (#{@result.covered_lines}/#{@result.total_lines} lines)",
          horizontal_rule
        ].join("\n")
      end

      # ----------------------------------------------------
      # Section 2 – Group table (mirrors HTML sidebar)
      # ----------------------------------------------------
      def group_table
        return '' if @result.groups.empty?

        name_width = @result.groups.keys.map(&:length).max
        header     = 'Coverage by group:'

        body = @result.groups.sort_by(&:first).map do |name, files|
          percent = SimpleCov::FileList.new(files).covered_percent
          format("  %-#{name_width}s : %6.2f %%", name, percent)
        end

        ([header] + body).join("\n") << "\n"
      end

      # ----------------------------------------------------
      # Section 3 – File-level detail incl. uncovered lines
      # ----------------------------------------------------
      def file_details
        header = horizontal_rule(' PER-FILE DETAIL ')

        body = @result.files.sort_by { |f| [f.covered_percent, f.filename] }.map do |file|
          file_summary(file)
        end

        ( [header] + body ).join("\n")
      end

      # @param file [SimpleCov::SourceFile]
      # @return     [String]
      def file_summary(file)
        covered = format('%6.2f', file.covered_percent)
        rel     = file.filename.sub(%r{\A#{Regexp.escape Dir.pwd}/?}, '')

        missed = format_missed_ranges(file.missed_lines.map(&:line_number))

        <<~SUMMARY.chomp
          #{covered} %  #{rel}
            └─ missed lines: #{missed.empty? ? '—' : missed}
        SUMMARY
      end

      # ----------------------------------------------------
      # Utility helpers
      # ----------------------------------------------------
      # Turns a sorted array like [3,4,5,10,12,13] into "3-5, 10, 12-13".
      #
      # @param line_numbers [Array<Integer>]
      # @return             [String]
      def format_missed_ranges(line_numbers)
        return '' if line_numbers.empty?

        ranges = []
        start  = prev = line_numbers.first

        line_numbers[1..].each do |n|
          if n == prev + 1
            prev = n
          else
            ranges << range_string(start, prev)
            start = prev = n
          end
        end
        ranges << range_string(start, prev)

        ranges.join(', ')
      end

      def range_string(a, b) = (a == b ? a.to_s : "#{a}-#{b}")

      def horizontal_rule(title = nil, width: 60, char: '=')
        return char * width unless title

        pad      = (width - title.length).clamp(0, width)
        left_pad = char * (pad / 2)
        right_pad = char * (pad - left_pad.length)
        "#{left_pad}#{title}#{right_pad}"
      end
    end
  end
end 