Feature: SimpleDodgeCommand action
  In order to let players dodge incoming attacks
  As a maintainer of the Aethyr engine
  I want SimpleDodgeCommand#action to correctly handle all dodge scenarios.

  Background:
    Given a stubbed SimpleDodge environment

  # --- Combat not ready ---
  Scenario: Combat not ready causes early return
    Given SimpleDodge Combat is not ready
    When the SimpleDodgeCommand action is invoked
    Then the dodge player should have no output

  # --- Target is self ---
  Scenario: Targeting self outputs cannot block yourself
    Given SimpleDodge Combat is ready
    And the dodge target is the player themselves
    When the SimpleDodgeCommand action is invoked
    Then the dodge player should see "You cannot block yourself."

  # --- Explicit target, but no blockable events ---
  Scenario: Explicit target with no blockable events outputs what are you trying to dodge
    Given SimpleDodge Combat is ready
    And the dodge target is "enemy"
    And there are no dodge blockable events for the target
    When the SimpleDodgeCommand action is invoked
    Then the dodge player should see "What are you trying to dodge?"

  # --- No target at all, no blockable events ---
  Scenario: No target and no blockable events outputs what are you trying to dodge
    Given SimpleDodge Combat is ready
    And there is no dodge target
    And there are no general dodge blockable events
    When the SimpleDodgeCommand action is invoked
    Then the dodge player should see "What are you trying to dodge?"

  # --- Explicit target, blockable events exist, rand > 0.5 (martial miss) ---
  Scenario: Successful dodge with explicit target and rand above 0.5 triggers martial_miss
    Given SimpleDodge Combat is ready
    And the dodge target is "enemy"
    And there are dodge blockable events for the target
    And dodge rand will return above 0.5
    When the SimpleDodgeCommand action is invoked
    Then the dodge event action should be :martial_miss
    And the dodge event type should be :MartialCombat
    And the dodge event to_other on b_event should contain "twists away from"
    And the dodge event to_player on b_event should contain "twists away from your attack"
    And the dodge event to_target on b_event should contain "You manage to twist your body away from"
    And the dodge command to_other should contain "attempts to dodge"
    And the dodge command to_target should contain "attempts to dodge your attack"
    And the dodge command to_player should contain "You attempt to dodge"
    And the dodge player balance should be false
    And the dodge room should receive out_event

  # --- Explicit target, blockable events exist, rand <= 0.5 (no martial_miss) ---
  Scenario: Successful dodge with explicit target and rand at or below 0.5 skips martial_miss
    Given SimpleDodge Combat is ready
    And the dodge target is "enemy"
    And there are dodge blockable events for the target
    And dodge rand will return at or below 0.5
    When the SimpleDodgeCommand action is invoked
    Then the dodge command to_other should contain "attempts to dodge"
    And the dodge command to_target should contain "attempts to dodge your attack"
    And the dodge command to_player should contain "You attempt to dodge"
    And the dodge player balance should be false
    And the dodge room should receive out_event

  # --- No explicit target, falls back to last_target ---
  Scenario: No explicit target falls back to last_target and finds blockable events
    Given SimpleDodge Combat is ready
    And there is no dodge target
    And the dodge player has a last_target of "enemy"
    And there are dodge blockable events for the target
    And dodge rand will return at or below 0.5
    When the SimpleDodgeCommand action is invoked
    Then the dodge command to_other should contain "attempts to dodge"
    And the dodge player balance should be false
    And the dodge room should receive out_event

  # --- No target resolved at all, but general blockable events found (target from selfs) ---
  Scenario: No target resolved but general blockable events set target from event player
    Given SimpleDodge Combat is ready
    And there is no dodge target
    And the dodge player has no last_target
    And there are general dodge blockable events with an attacker
    And dodge rand will return at or below 0.5
    When the SimpleDodgeCommand action is invoked
    Then the dodge player last_target should be set to the attacker goid
    And the dodge command to_other should contain "attempts to dodge"
    And the dodge player balance should be false
    And the dodge room should receive out_event
