Feature: KickCommand action
  In order to let players kick targets in combat
  As a maintainer of the Aethyr engine
  I want KickCommand#action to correctly handle all kick scenarios.

  Background:
    Given a stubbed Kick environment

  # --- Combat not ready ---
  Scenario: Combat not ready causes early return
    Given Kick Combat is not ready
    When the KickCommand action is invoked
    Then the kick player should have no output
    And the kick room should not receive out_event

  # --- No target found ---
  Scenario: No target found outputs who are you trying to attack
    Given Kick Combat is ready
    And there is no kick target
    And the kick player has no last_target
    When the KickCommand action is invoked
    Then the kick player should see "Who are you trying to attack?"

  # --- Target found but Combat.valid_target? returns false ---
  Scenario: Target found but invalid causes early return
    Given Kick Combat is ready
    And the kick target is "enemy"
    And Kick Combat valid_target returns false
    When the KickCommand action is invoked
    Then the kick player should have no output
    And the kick room should not receive out_event

  # --- Successful kick with explicit target ---
  Scenario: Successful kick with explicit target
    Given Kick Combat is ready
    And the kick target is "enemy"
    And Kick Combat valid_target returns true
    When the KickCommand action is invoked
    Then the kick player last_target should be set to the target goid
    And the kick player balance should be false
    And the kick player info in_combat should be true
    And the kick target info in_combat should be true
    And the kick room should receive out_event
    And the kick command action should be :martial_hit
    And the kick command combat_action should be :kick
    And the kick command blockable should be true
    And the kick command to_other should contain "kicks"
    And the kick command to_other should contain "considerable violence"
    And the kick command to_target should contain "kicks you rather violently"
    And the kick command to_player should contain "Your kick makes good contact with"
    And Kick Combat future_event should have been called

  # --- Target found via last_target fallback ---
  Scenario: Target found via last_target fallback
    Given Kick Combat is ready
    And there is no kick target
    And the kick player has a last_target of "enemy"
    And Kick Combat valid_target returns true
    When the KickCommand action is invoked
    Then the kick player last_target should be set to the target goid
    And the kick player balance should be false
    And the kick player info in_combat should be true
    And the kick target info in_combat should be true
    And the kick room should receive out_event
    And the kick command action should be :martial_hit
    And Kick Combat future_event should have been called
