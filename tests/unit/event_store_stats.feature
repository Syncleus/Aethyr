Feature: Event store statistics script

  In order to monitor the health and performance of the event sourcing system
  As a developer of the Aethyr engine
  I want the event_store_stats script to display detailed statistics
  about the event store, or report errors when the system is unavailable

  Scenario: Manager not initialised or event sourcing not enabled
    Given the stats require for aethyr is stubbed
    And no manager is available for stats
    When I load the event store stats script
    Then the stats output should include "Error: Manager not initialized or event sourcing not enabled"

  Scenario: Event store returns empty statistics
    Given the stats require for aethyr is stubbed
    And a manager whose event store stats are empty
    When I load the event store stats script
    Then the stats output should include "Event Store Statistics"
    And the stats output should include "======================"
    And the stats output should include "Event store not available or no statistics available"

  Scenario: Event store returns full statistics with aggregate counts and event types
    Given the stats require for aethyr is stubbed
    And a manager whose event store stats include aggregate counts and event types
    When I load the event store stats script
    Then the stats output should include "Event Store Statistics"
    And the stats output should include "======================"
    And the stats output should include "Total events stored: 100"
    And the stats output should include "Total events loaded: 80"
    And the stats output should include "Total snapshots stored: 10"
    And the stats output should include "Total snapshots loaded: 5"
    And the stats output should include "Store failures: 2"
    And the stats output should include "Load failures: 1"
    And the stats output should include "Aggregate count: 25"
    And the stats output should include "Event count: 100"
    And the stats output should include "Snapshot count: 10"
    And the stats output should include "Event Types:"
    And the stats output should include "  GameObjectCreated: 50"
    And the stats output should include "  PlayerCreated: 30"
    And the stats output should include "  RoomCreated: 20"

  # -------------------------------------------------------------------------
  # ServerConfig creation branch - exercises lines 57-61 of the step defs
  # when ServerConfig is not yet defined.
  # -------------------------------------------------------------------------
  Scenario: Script runs after ServerConfig is removed and re-created by stub
    Given ServerConfig is temporarily removed
    And the stats require for aethyr is stubbed
    And no manager is available for stats
    When I load the event store stats script
    Then the stats output should include "Error: Manager not initialized or event sourcing not enabled"

  # -------------------------------------------------------------------------
  # Coverage-snapshot merging logic - exercises the EventStoreStatsCovMerger
  # methods that were previously inlined in the SimpleCov adapter hook.
  # -------------------------------------------------------------------------
  Scenario: Merging an empty set of snapshots returns nil
    Given an empty set of coverage snapshots
    When I merge the coverage snapshots
    Then the merged snapshot should be nil

  Scenario: Merging a single snapshot returns a copy of that snapshot
    Given a single coverage snapshot "[1, null, 0, 3]"
    When I merge the coverage snapshots
    Then the merged snapshot should be "[1, null, 0, 3]"

  Scenario: Merging two snapshots uses max per line
    Given coverage snapshots "[1, null, 0, 3]" and "[0, null, 5, 2]"
    When I merge the coverage snapshots
    Then the merged snapshot should be "[1, null, 5, 3]"

  Scenario: Injecting merged data into a Hash lines entry
    Given a coverage result hash with a Hash lines entry for "/path/to/event_store_stats.rb"
    When I inject merged data "[5, 3, 1]" into the coverage result
    Then the coverage result for "/path/to/event_store_stats.rb" should have lines "[5, 3, 1]"

  Scenario: Injecting merged data into an Array entry
    Given a coverage result hash with an Array entry for "/path/to/event_store_stats.rb"
    When I inject merged data "[5, 3, 1]" into the coverage result
    Then the coverage result for "/path/to/event_store_stats.rb" should have lines "[5, 3, 1]"

  Scenario: Injecting merged data into an opaque entry wraps it in a Hash
    Given a coverage result hash with a String entry for "/path/to/event_store_stats.rb"
    When I inject merged data "[5, 3, 1]" into the coverage result
    Then the coverage result for "/path/to/event_store_stats.rb" should have lines "[5, 3, 1]"

  Scenario: Injecting nil merged data is a no-op
    Given a coverage result hash with a Hash lines entry for "/path/to/event_store_stats.rb"
    When I inject nil merged data into the coverage result
    Then the coverage result for "/path/to/event_store_stats.rb" should be unchanged

  Scenario: Applying coverage merging delegates to merge and inject
    When I apply coverage merging for snapshots "[[1, null, 5]]" to result with Hash entry for "/path/to/event_store_stats.rb"
    Then the coverage result for "/path/to/event_store_stats.rb" should have lines "[1, null, 5]"

  Scenario: Installing SimpleCov hook when SimpleCov is not loaded returns false
    Given SimpleCov is temporarily hidden
    When I install the SimpleCov hook
    Then the hook installation should return false

  Scenario: Installing and invoking SimpleCov hook with a mock adapter
    Given a mock SimpleCov ResultAdapter is defined
    When I install the SimpleCov hook with the mock adapter
    Then the hook installation should return true
    When I invoke the hooked adapter with snapshots "[[1, null, 5]]" and Hash entry for "/path/to/event_store_stats.rb"
    Then the coverage result for "/path/to/event_store_stats.rb" should have lines "[1, null, 5]"
