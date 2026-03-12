Feature: PunchCommand action
  In order to let players punch enemies with their fists
  As a maintainer of the Aethyr engine
  I want PunchCommand#action to correctly handle all punch scenarios.

  Background:
    Given a stubbed PunchCommand environment

  # --- Combat not ready (line 17) ---
  Scenario: Combat not ready causes early return
    Given punch combat is not ready
    When the PunchCommand action is invoked
    Then the punch player should have no output

  # --- No target found at all (lines 21-23) ---
  Scenario: No target outputs who are you trying to attack
    Given punch combat is ready
    And there is no punch target
    And the punch player has no punch last_target
    When the PunchCommand action is invoked
    Then the punch player should see "Who are you trying to attack?"

  # --- Target found but Combat.valid_target? returns false (line 25) ---
  Scenario: Invalid target causes early return from valid_target check
    Given punch combat is ready
    And the punch target is "goblin"
    And punch combat valid_target returns false
    When the PunchCommand action is invoked
    Then the punch player should not see "Who are you trying to attack?"

  # --- Full successful punch with explicit target (lines 28-49) ---
  Scenario: Successful punch with explicit target completes full combat action
    Given punch combat is ready
    And the punch target is "goblin"
    And punch combat valid_target returns true
    When the PunchCommand action is invoked
    Then the punch player last_target should be set to the punch target goid
    And the punch command to_other should contain "punches"
    And the punch command to_other should contain "Goblin"
    And the punch command to_target should contain "punches you in the face"
    And the punch command to_player should contain "Goblin"
    And the punch command to_player should contain "face"
    And the punch command action should be :martial_hit
    And the punch command combat_action should be :punch
    And the punch command blockable should be true
    And the punch player balance should be false
    And the punch player should be in combat
    And the punch target should be in combat
    And the punch room should have received out_event
    And punch combat should have received future_event

  # --- Successful punch falling back to last_target (line 19) ---
  Scenario: Punch with no explicit target falls back to last_target
    Given punch combat is ready
    And there is no punch target
    And the punch player punch last_target is "goblin"
    And punch combat valid_target returns true
    When the PunchCommand action is invoked
    Then the punch player last_target should be set to the punch target goid
    And the punch command to_player should contain "Goblin"
    And the punch command action should be :martial_hit
    And the punch command combat_action should be :punch
    And the punch player balance should be false
    And the punch room should have received out_event
    And punch combat should have received future_event
