#!/usr/bin/env ruby

# @author Aethyr Development Team
# @since 1.0.0
#
# This script migrates existing game objects to the event store.
# It loads all objects from the traditional storage system and creates
# corresponding events in the event store to establish a complete history.
#
# The migration process handles different types of game objects:
# - Players (including password hashes and admin status)
# - Rooms (including exits and descriptions)
# - Regular game objects (with their attributes and container relationships)
#
# The migration is performed by calling the StorageMachine#migrate_to_event_store method,
# which creates appropriate commands for each object type and executes them through
# the Sequent command service. This ensures that all objects are properly represented
# in the event store with their complete state.
#
# Usage:
#   ruby lib/aethyr/migrate_to_event_store.rb
#
# Requirements:
#   - The Aethyr server must be running
#   - Event sourcing must be enabled in the configuration
#   - The Sequent gem must be installed
#   - ImmuDB must be properly configured (or file-based fallback will be used)
#
# @example Running the migration script
#   $ ruby lib/aethyr/migrate_to_event_store.rb
#   Starting migration to event store...
#   Migration completed successfully!

# Load the application
$LOAD_PATH.unshift File.expand_path('../../', __FILE__)
require 'aethyr'

if $manager && $manager.storage
  puts "Starting migration to event store..."
  result = $manager.storage.migrate_to_event_store
  if result
    puts "Migration completed successfully!"
  else
    puts "Migration failed. Check logs for details."
  end
else
  puts "Error: Manager or storage not initialized"
end
