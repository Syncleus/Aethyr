@respawns
Feature: Respawns trait
  The Respawns module is mixed into Mobiles so they automatically respawn
  after they die. It tracks a respawn_area, respawn_rate, and respawn_time.

  # ── initialize ──────────────────────────────────────────────────────

  Scenario: Initialize with a container sets respawn_area
    Given I have a respawns test object with container "zone_1"
    Then the respawns object respawn_area should be "zone_1"
    And the respawns object respawn_rate should be 900
    And the respawns object respawn_time should be nil

  Scenario: Initialize without a container leaves respawn_area nil
    Given I have a respawns test object without container
    Then the respawns object respawn_area should be nil
    And the respawns object respawn_rate should be 900
    And the respawns object respawn_time should be nil

  # ── run ─────────────────────────────────────────────────────────────

  Scenario: Run when alive does not trigger respawn
    Given I have a respawns test object without container
    And the respawns object is alive
    And the respawns object respawn_time is in the past
    When I run the respawns object
    Then the respawns object should have no log messages

  Scenario: Run when not alive and respawn_time has passed triggers respawn
    Given I have a respawns test object without container
    And the respawns object is not alive
    And the respawns object respawn_time is in the past
    When I run the respawns object expecting respawn
    Then the respawns object log should include "Cannot respawn"

  Scenario: Run when not alive but respawn_time is in the future does not trigger respawn
    Given I have a respawns test object without container
    And the respawns object is not alive
    And the respawns object respawn_time is in the future
    When I run the respawns object
    Then the respawns object should have no log messages

  Scenario: Run when not alive and respawn_time is nil does not trigger respawn
    Given I have a respawns test object without container
    And the respawns object is not alive
    When I run the respawns object
    Then the respawns object should have no log messages

  # ── respawn_in ──────────────────────────────────────────────────────

  Scenario: respawn_in sets respawn_time to the given seconds from now
    Given I have a respawns test object without container
    When I call respawns respawn_in with 600 seconds
    Then the respawns object respawn_time should be approximately 600 seconds from now

  # ── respawn with nil respawn_area ───────────────────────────────────

  Scenario: Respawn with nil respawn_area logs an error
    Given I have a respawns test object without container
    And the respawns object is not alive
    And the respawns object respawn_time is in the past
    When I run the respawns object expecting respawn
    Then the respawns object log should include "Cannot respawn! No info.respawn_area set."

  # ── respawn with Enumerable respawn_area ────────────────────────────

  Scenario: Respawn with Enumerable respawn_area and Area result picks random room
    Given I have a respawns test object without container
    And the respawns object is not alive
    And the respawns object has an enumerable respawn_area returning an Area with rooms
    And the respawns object respawn_time is in the past
    When I run the respawns object expecting raise "respawn no longer works"
    Then the respawns raised error message should include "respawn no longer works"

  Scenario: Respawn with non-Enumerable respawn_area and Room result
    Given I have a respawns test object without container
    And the respawns object is not alive
    And the respawns object has a direct respawn_area returning a Room
    And the respawns object respawn_time is in the past
    When I run the respawns object expecting raise "respawn no longer works"
    Then the respawns raised error message should include "respawn no longer works"

  Scenario: Respawn with non-Enumerable respawn_area and Container result
    Given I have a respawns test object without container
    And the respawns object is not alive
    And the respawns object has a direct respawn_area returning a Container
    And the respawns object respawn_time is in the past
    When I run the respawns object expecting raise "respawn no longer works"
    Then the respawns raised error message should include "respawn no longer works"

  Scenario: Respawn with area that is Enumerable but not Area/Room/Container
    Given I have a respawns test object without container
    And the respawns object is not alive
    And the respawns object has a direct respawn_area returning a generic Enumerable
    And the respawns object respawn_time is in the past
    When I run the respawns object expecting raise "respawn no longer works"
    Then the respawns raised error message should include "respawn no longer works"

  Scenario: Respawn with area that is an unknown type logs error
    Given I have a respawns test object without container
    And the respawns object is not alive
    And the respawns object has a direct respawn_area returning an unknown type
    And the respawns object respawn_time is in the past
    When I run the respawns object expecting respawn
    Then the respawns object log should include "not respawning"

  Scenario: Respawn where room lookup returns nil logs error
    Given I have a respawns test object without container
    And the respawns object is not alive
    And the respawns object has an enumerable respawn_area returning an Area with nil room
    And the respawns object respawn_time is in the past
    When I run the respawns object expecting respawn
    Then the respawns object log should include "Cannot find respawn area"

  Scenario: Respawn reaching the raise with Area path
    Given I have a respawns test object without container
    And the respawns object is not alive
    And the respawns object has a direct respawn_area returning an Area with rooms
    And the respawns object respawn_time is in the past
    When I run the respawns object expecting raise "respawn no longer works"
    Then the respawns raised error message should include "respawn no longer works"
    And the respawns object respawn_time should be nil
