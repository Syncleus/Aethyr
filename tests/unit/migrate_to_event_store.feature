Feature: Migrate to event store script

  In order to transition legacy game-object storage to the event store
  As a developer of the Aethyr engine
  I want the migration script to invoke StorageMachine#migrate_to_event_store
  and report success, failure, or initialisation errors

  Scenario: Successful migration
    Given the migration environment is prepared
    When I run the migration script with a successful storage migration
    Then the migration output should include "Starting migration to event store..."
    And the migration output should include "Migration completed successfully!"

  Scenario: Failed migration
    Given the migration environment is prepared
    When I run the migration script with a failed storage migration
    Then the migration output should include "Starting migration to event store..."
    And the migration output should include "Migration failed. Check logs for details."

  Scenario: Manager or storage not initialised
    Given the migration environment is prepared
    When I run the migration script with no manager available
    Then the migration output should include "Error: Manager or storage not initialized"
