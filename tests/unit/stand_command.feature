Feature: StandCommand action
  In order to let players stand up from sitting or lying positions
  As a maintainer of the Aethyr engine
  I want StandCommand#action to correctly handle all stand scenarios.

  Background:
    Given a stubbed StandCommand environment

  # --- Branch 1: not prone (lines 17-19) ---
  Scenario: Player not prone sees already on feet message
    Given the stand player is not prone
    When the StandCommand action is invoked
    Then the stand player should see "You are already on your feet."

  # --- Branch 2: prone but no balance (lines 20-22) ---
  Scenario: Prone but unbalanced player cannot stand
    Given the stand player is prone
    And the stand player is not balanced
    When the StandCommand action is invoked
    Then the stand player should see "You cannot stand while unbalanced."

  # --- Branch 3: sitting, stand succeeds, object exists (lines 25-26, 31-36) ---
  Scenario: Sitting player stands successfully with object present
    Given the stand player is prone
    And the stand player is balanced
    And the stand player is sitting on "chair_1"
    And the stand manager finds object "chair_1" in room
    And the stand player can stand
    When the StandCommand action is invoked
    Then the stand event to_player should be "You rise to your feet."
    And the stand event to_other should be "TestPlayer stands up."
    And the stand event to_deaf_other should be "TestPlayer stands up."
    And the stand room should receive out_event
    And the stand object should receive evacuated_by

  # --- Branch 4: lying, stand succeeds, object nil (lines 25, 28, 31-35) ---
  Scenario: Lying player stands successfully with no object found
    Given the stand player is prone
    And the stand player is balanced
    And the stand player is lying on "floor_1"
    And the stand manager does not find any object
    And the stand player can stand
    When the StandCommand action is invoked
    Then the stand event to_player should be "You rise to your feet."
    And the stand event to_other should be "TestPlayer stands up."
    And the stand event to_deaf_other should be "TestPlayer stands up."
    And the stand room should receive out_event
    And the stand object should not receive evacuated_by

  # --- Branch 5: stand fails (lines 37-38) ---
  Scenario: Player unable to stand outputs failure message
    Given the stand player is prone
    And the stand player is balanced
    And the stand player is sitting on "chair_1"
    And the stand manager finds object "chair_1" in room
    And the stand player cannot stand
    When the StandCommand action is invoked
    Then the stand player should see "You are unable to stand up."

  # --- Extra: lying, stand succeeds, object exists ---
  Scenario: Lying player stands successfully with object present
    Given the stand player is prone
    And the stand player is balanced
    And the stand player is lying on "bed_1"
    And the stand manager finds object "bed_1" in room
    And the stand player can stand
    When the StandCommand action is invoked
    Then the stand event to_player should be "You rise to your feet."
    And the stand event to_other should be "TestPlayer stands up."
    And the stand room should receive out_event
    And the stand object should receive evacuated_by

  # --- Extra: sitting, stand succeeds, object nil ---
  Scenario: Sitting player stands successfully with no object found
    Given the stand player is prone
    And the stand player is balanced
    And the stand player is sitting on "ghost_chair"
    And the stand manager does not find any object
    And the stand player can stand
    When the StandCommand action is invoked
    Then the stand event to_player should be "You rise to your feet."
    And the stand room should receive out_event
    And the stand object should not receive evacuated_by
