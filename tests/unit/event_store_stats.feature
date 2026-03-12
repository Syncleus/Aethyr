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
