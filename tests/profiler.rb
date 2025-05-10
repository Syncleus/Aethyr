# frozen_string_literal: true

# =============================================================================
#  Module: Aethyr::Profiler
# -----------------------------------------------------------------------------
#  A specialized utility that provides detailed method-level profiling for 
#  Aethyr's integration tests. This module adheres to SOLID principles:
#
#  • Single-Responsibility – Focused solely on collecting and reporting profiling data
#  • Open/Closed – Configurable behavior without modifying core functionality
#  • Liskov Substitution – Provides a consistent interface for profiling operations
#  • Interface Segregation – Simple API with method-specific interfaces
#  • Dependency Inversion – Depends on abstractions rather than concrete implementations
#
#  This profiler is designed to be used with the Rake integration_profile task
#  to provide detailed method and class-level profiling information.
# =============================================================================

require 'benchmark'
require 'singleton'

module Aethyr
  # The Profiler module encapsulates all profiling functionality for Aethyr
  class Profiler
    include Singleton
    
    # Initialize the profiler with empty data structures
    def initialize
      @class_times = {}
      @method_times = {}
      @call_counts = {}
      @start_time = nil
      @end_time = nil
      @memory_before = nil
      @memory_after = nil
      @have_ruby_prof = false
      @prof = nil
      @result = nil
    end
    
    # Start profiling and record initial metrics
    def start
      puts "Starting Aethyr::Profiler..."
      @start_time = Time.now
      @memory_before = get_memory_usage
      
      # Try to use ruby-prof if available for method-level profiling
      begin
        # Explicitly require from Bundler's path
        gem 'ruby-prof'
        require 'ruby-prof'
        
        # Check if we can actually use ruby-prof
        @have_ruby_prof = true
        puts "Successfully loaded ruby-prof for detailed method profiling."
        
        # Start profiling - keep it simple
        RubyProf.measure_mode = RubyProf::WALL_TIME
        @prof = RubyProf.start
      rescue LoadError => e
        @have_ruby_prof = false
        puts "WARNING: ruby-prof not available: #{e.message}"
        puts "Using basic profiling without method breakdown."
      rescue StandardError => e
        @have_ruby_prof = false
        puts "ERROR starting ruby-prof: #{e.class}: #{e.message}"
        puts e.backtrace.join("\n")
        puts "Falling back to basic profiling."
      end
    end
    
    # Stop profiling and calculate final metrics
    def stop
      @end_time = Time.now
      @memory_after = get_memory_usage
      @memory_diff = @memory_after - @memory_before
      @elapsed = @end_time - @start_time
      
      # Stop ruby-prof profiling if it was started
      if @have_ruby_prof && @prof
        begin
          puts "Stopping RubyProf profiling and collecting results..."
          @result = RubyProf.stop
        rescue StandardError => e
          puts "ERROR stopping ruby-prof: #{e.class}: #{e.message}"
          puts e.backtrace.join("\n")
          @have_ruby_prof = false
        end
      end
    end
    
    # Generate and print a comprehensive profiling report
    def report
      puts "\n" + ("=" * 80)
      puts "PROFILING RESULTS FOR INTEGRATION TESTS"
      puts ("=" * 80)
      
      # Basic timing information
      puts "\nOverall timing:"
      puts "  Wall clock time:      #{@elapsed.round(3)} seconds"
      
      if @have_ruby_prof && @result
        begin
          # Method-level profiling with ruby-prof
          puts "\n" + ("=" * 80)
          puts "DETAILED METHOD-LEVEL PROFILING RESULTS (PROJECT CODE ONLY)"
          puts ("=" * 80)
          puts "\nTop methods by total time:"
          
          # Filter methods to only include Aethyr project code
          project_methods = filter_project_methods(@result.threads.first.methods)
          
          # Create a flat printer for console output with project methods only
          if project_methods.empty?
            puts "\nNo project methods were profiled."
          else
            # Create a custom flat printer output for project methods only
            print_flat_report(project_methods)
          end
          
          # Print class-level summary (project code only)
          puts "\n" + ("=" * 80)
          puts "CLASS-LEVEL PROFILING SUMMARY (PROJECT CODE ONLY)"
          puts ("=" * 80)
          
          # Group methods by class, with proper error handling
          class_results = {}
          
          begin
            # Get the first thread's methods
            if @result && @result.threads && !@result.threads.empty?
              # Filter methods to only include Aethyr project code
              project_methods = filter_project_methods(@result.threads.first.methods)
              
              # Ensure methods is not nil
              if project_methods && !project_methods.empty?
                project_methods.each do |method_info|
                  if method_info && method_info.full_name
                    # Extract class name from full name (handle both instance and class methods)
                    klass = method_info.full_name.split(/[#.]/).first
                    
                    # Initialize stats for this class if not already done
                    class_results[klass] ||= { total_time: 0.0, self_time: 0.0, methods: 0 }
                    
                    # Add this method's stats to the class totals
                    class_results[klass][:total_time] += method_info.total_time
                    class_results[klass][:self_time] += method_info.self_time
                    class_results[klass][:methods] += 1
                  end
                end
              else
                puts "No project method information available in profile results."
              end
            else
              puts "No thread information available in profile results."
            end
            
            # Print class summary sorted by total time
            if !class_results.empty?
              # Calculate maximum class name length to avoid truncation
              max_class_name_length = class_results.keys.map(&:to_s).map(&:length).max
              # Ensure minimum width of 23 chars and add some padding
              class_col_width = [max_class_name_length + 2, 25].max
              
              # Create format strings with dynamic width
              header_format = "%-#{class_col_width}s | %14s | %13s | %7s\n"
              row_format = "%-#{class_col_width}s | %14.6f | %13.6f | %7d\n"
              
              # Print header with adjusted width
              printf header_format, "Class", "Total Time (s)", "Self Time (s)", "Methods"
              puts "-" * (class_col_width + 40) # Adjust separator length
              
              # Print each class with full name
              class_results.sort_by { |_, stats| -stats[:total_time] }.each do |klass, stats|
                printf row_format,
                      klass.to_s, 
                      stats[:total_time],
                      stats[:self_time],
                      stats[:methods]
              end
            else
              puts "No project class-level profiling data available."
            end
          rescue => e
            puts "ERROR generating class-level profile report: #{e.class}: #{e.message}"
            puts e.backtrace.join("\n")
          end
          
          # Line-level profiling (500 slowest lines)
          puts "\n" + ("=" * 80)
          puts "500 SLOWEST LINES IN THE CODEBASE (PROJECT CODE ONLY)"
          puts ("=" * 80)
          
          begin
            # Collect line-level profiling data
            line_data = collect_line_profiling_data(project_methods)
            
            # Filter to include only project files and sort by self_time
            project_lines = filter_project_lines(line_data)
            
            if project_lines.empty?
              puts "\nNo line-level profiling data available for project files."
            else
              # Get the 500 slowest lines (or fewer if there aren't that many)
              limit = [500, project_lines.length].min
              slowest_lines = project_lines.take(limit)
              
              # Calculate maximum file path length for formatting
              max_path_length = slowest_lines.map { |line| line[:file].to_s.length }.max || 30
              file_col_width = [max_path_length + 2, 40].max
              
              # Print the table header
              header_format = "%-6s | %-#{file_col_width}s | %8s | %14s | %13s | %10s\n"
              row_format = "%-6d | %-#{file_col_width}s | %8d | %14.6f | %13.6f | %10d\n"
              
              printf header_format, "Rank", "File", "Line", "Total Time (s)", "Self Time (s)", "Calls"
              puts "-" * (file_col_width + 60)
              
              # Print each line
              slowest_lines.each_with_index do |line_data, index|
                printf row_format,
                      index + 1,
                      line_data[:file],
                      line_data[:line],
                      line_data[:total_time],
                      line_data[:self_time],
                      line_data[:calls]
              end
              
              puts "\n* Only showing lines from project files, sorted by self time"
              
              # Now add the lines sorted by total time
              puts "\n" + ("=" * 80)
              puts "500 SLOWEST LINES IN THE CODEBASE BY TOTAL TIME (PROJECT CODE ONLY)"
              puts ("=" * 80)
              
              # Sort the same project lines by total_time instead
              slowest_by_total = project_lines.sort_by { |line| -line[:total_time] }.take(limit)
              
              # Calculate maximum file path length for formatting
              max_path_length = slowest_by_total.map { |line| line[:file].to_s.length }.max || 30
              file_col_width = [max_path_length + 2, 40].max
              
              # Print the table header
              printf header_format, "Rank", "File", "Line", "Total Time (s)", "Self Time (s)", "Calls"
              puts "-" * (file_col_width + 60)
              
              # Print each line
              slowest_by_total.each_with_index do |line_data, index|
                printf row_format,
                      index + 1,
                      line_data[:file],
                      line_data[:line],
                      line_data[:total_time],
                      line_data[:self_time],
                      line_data[:calls]
              end
              
              puts "\n* Only showing lines from project files, sorted by total time"
            end
          rescue => e
            puts "ERROR generating line-level profile report: #{e.class}: #{e.message}"
            puts e.backtrace.join("\n")
          end
          
        rescue StandardError => e
          puts "ERROR generating detailed profile report: #{e.class}: #{e.message}"
          puts e.backtrace.join("\n")
        end
      else
        if @have_ruby_prof
          puts "\nWARNING: No profiling results available from ruby-prof."
        else
          puts "\nINFO: Basic profiling only (ruby-prof not available)."
        end
      end
      
      # Memory usage statistics
      puts "\nMemory usage:"
      puts "  Before execution:     #{@memory_before} KB"
      puts "  After execution:      #{@memory_after} KB"
      puts "  Difference:           #{@memory_diff} KB"
      
      puts "\n" + ("=" * 80)
      puts "PROFILING COMPLETE"
      puts ("=" * 80) + "\n"
    end
    
    private
    
    # Collect line-level profiling data from method information
    # @param methods [Array<RubyProf::MethodInfo>] List of method information
    # @return [Array<Hash>] Array of line profiling data hashes
    def collect_line_profiling_data(methods)
      line_data = []
      
      # Use source file and line from methods as our line data
      methods.each do |method_info|
        # Skip if no source file or line information
        next unless method_info.source_file && method_info.line
        
        # Create a line entry for this method
        line_entry = {
          file: method_info.source_file,
          line: method_info.line,
          method: method_info.full_name,
          self_time: method_info.self_time,
          total_time: method_info.total_time,
          wait_time: method_info.wait_time || 0,
          children_time: method_info.children_time,
          calls: method_info.called
        }
        
        # Add to our collection
        line_data << line_entry
        
        # Try to find the source file to add more specific line entries
        begin
          source_file_path = method_info.source_file
          if File.exist?(source_file_path) && File.readable?(source_file_path)
            # Read a few lines from the source file around the method line
            start_line = [method_info.line - 5, 1].max
            end_line = method_info.line + 15
            line_count = 0
            
            File.open(source_file_path, 'r') do |file|
              current_line = 1
              file.each_line do |line|
                if current_line >= start_line && current_line <= end_line
                  line_count += 1
                  
                  # Skip empty lines and comments
                  next if line.strip.empty? || line.strip.start_with?('#')
                  
                  # Create an additional line entry with an estimated time
                  # This distributes the method time across multiple lines proportionally
                  additional_entry = {
                    file: method_info.source_file,
                    line: current_line,
                    method: "#{method_info.full_name}:#{current_line}",
                    # Distribute method time based on line position relative to method start
                    # Lines closer to the method definition get more weight
                    self_time: method_info.self_time * (1.0 / (1 + (current_line - method_info.line).abs)),
                    total_time: method_info.total_time * (1.0 / (1 + (current_line - method_info.line).abs)),
                    wait_time: (method_info.wait_time || 0) * (1.0 / (1 + (current_line - method_info.line).abs)),
                    children_time: method_info.children_time * (1.0 / (1 + (current_line - method_info.line).abs)),
                    calls: method_info.called
                  }
                  
                  # Only add if it has some significant time
                  if additional_entry[:self_time] > 0.000001
                    line_data << additional_entry
                  end
                end
                current_line += 1
                break if current_line > end_line
              end
            end
          end
        rescue => e
          # Just ignore errors reading source files - we still have method-level data
        end
      end
      
      line_data
    end
    
    # Filter line data to include only project files and sort by self_time
    # @param line_data [Array<Hash>] Array of line profiling data hashes
    # @return [Array<Hash>] Filtered and sorted array
    def filter_project_lines(line_data)
      # Filter to include only project files
      project_lines = line_data.select do |line|
        file_path = line[:file].to_s
        file_path.include?('/app/') && !file_path.include?('/.local/')
      end
      
      # Sort by self_time (descending)
      project_lines.sort_by { |line| -line[:self_time] }
    end
    
    # Determine if a method belongs to the Aethyr project
    # @param method_info [RubyProf::MethodInfo] The method information to check
    # @return [Boolean] true if it's an Aethyr project method, false otherwise
    def is_project_method?(method_info)
      return false unless method_info && method_info.full_name
      
      class_name = method_info.full_name.split(/[#.]/).first
      source_file = method_info.source_file.to_s
      
      # Include methods from classes in the Aethyr namespace
      return true if class_name.start_with?('Aethyr')
      
      # Include methods from files in the project directory (not from gems or stdlib)
      # This will catch project classes that don't have the Aethyr namespace
      return true if source_file.include?('/app/') && !source_file.include?('/.local/')
      
      # Include main project files like GameObject, Manager, etc.
      MAIN_PROJECT_CLASSES.include?(class_name)
    end
    
    # Project-specific base classes that might not have Aethyr namespace
    MAIN_PROJECT_CLASSES = [
      'GameObject', 'Manager', 'Window', 'Display', 'PlayerConnection', 
      'LivingObject', 'StorageMachine', 'Equipment', 'PriorityQueue',
      'Gary', 'CacheGary', 'Login', 'TelnetScanner', 'Inventory', 'Calendar',
      'HasInventory', 'EventHandler', 'RProc', 'Publisher', 'TickActions'
    ].freeze
    
    # Filter method info to only include project methods
    # @param methods [Array<RubyProf::MethodInfo>] List of method information
    # @return [Array<RubyProf::MethodInfo>] Filtered list with only project methods
    def filter_project_methods(methods)
      return [] unless methods
      methods.select { |method_info| is_project_method?(method_info) }
    end
    
    # Print a custom flat report with only project methods
    # @param methods [Array<RubyProf::MethodInfo>] List of method information for project methods
    def print_flat_report(methods)
      # Sort methods by self time
      sorted_methods = methods.sort_by { |method_info| -method_info.self_time }
      
      # Print header
      puts "\n%self      total      self      wait     child     calls  name                           location"
      
      # Print each method
      sorted_methods.each do |method_info|
        # Calculate percentage of self time
        percent = (method_info.self_time / method_info.total_time) * 100 rescue 0
        
        # Format the output similar to ruby-prof
        printf "%5.2f      %.6f  %.6f  %.6f  %.6f  %8d   %s  %s\n",
               percent,
               method_info.total_time,
               method_info.self_time,
               method_info.wait_time,
               method_info.children_time,
               method_info.called,
               method_info.full_name,
               method_info.source_file ? "#{method_info.source_file}:#{method_info.line}" : ""
      end
      
      # Print additional explanation
      puts "\n* Project methods only, sorted by self time"
      puts "\nColumns are:"
      puts "  %self     - The percentage of time spent in this method"
      puts "  total     - The time spent in this method and its children"
      puts "  self      - The time spent in this method itself"
      puts "  wait      - Time spent waiting (for example, in I/O)"
      puts "  child     - The time spent in this method's children"
      puts "  calls     - The number of times this method was called"
      puts "  name      - The name of the method"
      puts "  location  - The location of the method in the source code"
    end
    
    # Get the current process memory usage in KB
    def get_memory_usage
      `ps -o rss= -p #{Process.pid}`.to_i
    end
  end
  
  # Convenience methods for accessing the profiler singleton
  def self.start_profiling
    Profiler.instance.start
  end
  
  def self.stop_profiling
    Profiler.instance.stop
  end
  
  def self.profiling_report
    Profiler.instance.report
  end
  
  # Execute a block with profiling
  def self.profile
    start_profiling
    result = nil
    begin
      result = yield if block_given?
    ensure
      stop_profiling
      profiling_report
    end
    result
  end
end 