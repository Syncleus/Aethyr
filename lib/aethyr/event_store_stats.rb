#!/usr/bin/env ruby

# @author Aethyr Development Team
# @since 1.0.0
#
# This script displays detailed statistics about the event store.
# It provides information about the number of events, aggregates, and snapshots,
# as well as the distribution of event types.
#
# The statistics include:
# - Total events stored and loaded
# - Total snapshots stored and loaded
# - Store and load failures
# - Aggregate count
# - Event count
# - Snapshot count
# - Distribution of event types
#
# This information is useful for monitoring the health and performance
# of the event sourcing system and diagnosing any issues that may arise.
# Regular monitoring of these statistics can help identify trends and
# potential problems before they become critical.
#
# Usage:
#   ruby lib/aethyr/event_store_stats.rb
#
# Requirements:
#   - The Aethyr server must be running
#   - Event sourcing must be enabled in the configuration

# Load the application
$LOAD_PATH.unshift File.expand_path('../../', __FILE__)
require 'aethyr'

if $manager && ServerConfig[:event_sourcing_enabled]
  puts "Event Store Statistics"
  puts "======================"
  
  stats = $manager.event_store_stats
  
  if stats.empty?
    puts "Event store not available or no statistics available"
  else
    puts "Total events stored: #{stats[:events_stored]}"
    puts "Total events loaded: #{stats[:events_loaded]}"
    puts "Total snapshots stored: #{stats[:snapshots_stored]}"
    puts "Total snapshots loaded: #{stats[:snapshots_loaded]}"
    puts "Store failures: #{stats[:store_failures]}"
    puts "Load failures: #{stats[:load_failures]}"
    
    if stats[:aggregate_count]
      puts "\nAggregate count: #{stats[:aggregate_count]}"
      puts "Event count: #{stats[:event_count]}"
      puts "Snapshot count: #{stats[:snapshot_count]}"
    end
    
    if stats[:event_types] && !stats[:event_types].empty?
      puts "\nEvent Types:"
      stats[:event_types].sort_by { |_, count| -count }.each do |type, count|
        puts "  #{type}: #{count}"
      end
    end
  end
else
  puts "Error: Manager not initialized or event sourcing not enabled"
end
