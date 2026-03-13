Feature: Sittable trait
  The Sittable module is mixed into game objects so players can sit on them.
  It tracks occupants and enforces occupancy limits.

  Scenario: Sittable object can be created
    Given I have a sittable test object
    Then the sittable object should exist
    And the sittable object should report sittable as true

  Scenario: New sittable object is not occupied
    Given I have a sittable test object
    Then the sittable object should not be occupied

  Scenario: New sittable object has room
    Given I have a sittable test object
    Then the sittable object should have room

  Scenario: New sittable object has empty occupants
    Given I have a sittable test object
    Then the sittable object occupants should be empty

  Scenario: A player sits on the object
    Given I have a sittable test object
    And a mock player with goid "player_1"
    When the mock player sits on the sittable object
    Then the sittable object should be occupied
    And the sittable object should not have room
    And the sittable object occupants should include "player_1"
    And the sittable object should report occupied by the mock player

  Scenario: A player evacuates the object
    Given I have a sittable test object
    And a mock player with goid "player_1"
    And the mock player is already sitting on the sittable object
    When the mock player evacuates the sittable object
    Then the sittable object should not be occupied
    And the sittable object should have room
    And the sittable object occupants should not include "player_1"
    And the sittable object should not report occupied by the mock player

  Scenario: Occupied by returns false for a different player
    Given I have a sittable test object
    And a mock player with goid "player_1"
    And a second mock player with goid "player_2"
    And the mock player is already sitting on the sittable object
    Then the sittable object should not report occupied by the second mock player
