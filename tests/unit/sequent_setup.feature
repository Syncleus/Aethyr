Feature: SequentSetup orchestration
  The Aethyr::Core::EventSourcing::SequentSetup class orchestrates the
  initialization and configuration of the event sourcing system.  It provides
  methods to configure Sequent, rebuild world state from events, and retrieve
  event store statistics.  When the Sequent gem is not available, a graceful
  stub implementation is provided.

  # -------------------------------------------------------------------------
  #  Real implementation (Sequent gem IS available)
  # -------------------------------------------------------------------------

  Scenario: configure sets up Sequent and returns true
    Given the Sequent framework is available and mocked for setup
    When I call SequentSetup.configure
    Then the configure result should be true
    And Sequent should have been configured with an event store
    And Sequent should have been configured with command handlers
    And Sequent should have been configured with event handlers
    And Sequent should have been configured with an event publisher

  Scenario: rebuild_world_state with no manager returns true
    Given the Sequent framework is available and mocked for setup
    And the global manager is nil for sequent setup
    When I call SequentSetup.rebuild_world_state
    Then the rebuild result should be true

  Scenario: rebuild_world_state with manager whose objects are all in event store
    Given the Sequent framework is available and mocked for setup
    And a mock manager with game objects all present in the event store
    When I call SequentSetup.rebuild_world_state
    Then the rebuild result should be true
    And no objects should be reported as missing

  Scenario: rebuild_world_state with manager having objects missing from event store
    Given the Sequent framework is available and mocked for setup
    And a mock manager with game objects some missing from the event store
    When I call SequentSetup.rebuild_world_state
    Then the rebuild result should be true
    And the missing objects should have been detected

  Scenario: event_store_stats returns statistics when configured
    Given the Sequent framework is available and mocked for setup
    And Sequent configuration has an event store with statistics
    When I call SequentSetup.event_store_stats
    Then the stats result should include event count 42

  Scenario: event_store_stats returns empty hash when not configured
    Given Sequent configuration has no event store
    When I call SequentSetup.event_store_stats
    Then the stats result should be an empty hash

  # -------------------------------------------------------------------------
  #  Stub implementation (Sequent gem NOT available)
  # -------------------------------------------------------------------------

  Scenario: stub configure returns false when Sequent is unavailable
    Given the sequent setup file is loaded without Sequent available
    When I call stub SequentSetup.configure
    Then the stub configure result should be false

  Scenario: stub rebuild_world_state returns false when Sequent is unavailable
    Given the sequent setup file is loaded without Sequent available
    When I call stub SequentSetup.rebuild_world_state
    Then the stub rebuild result should be false

  Scenario: stub event_store_stats returns empty hash when Sequent is unavailable
    Given the sequent setup file is loaded without Sequent available
    When I call stub SequentSetup.event_store_stats
    Then the stub stats result should be an empty hash
