Feature: SimpleBlockCommand action
  In order to let players block incoming attacks
  As a maintainer of the Aethyr engine
  I want SimpleBlockCommand#action to correctly handle all block scenarios.

  Background:
    Given a stubbed SimpleBlock environment

  # --- Combat not ready ---
  Scenario: Combat not ready causes early return
    Given Combat is not ready
    When the SimpleBlockCommand action is invoked
    Then the block player should have no output

  # --- No weapon available ---
  Scenario: No weapon outputs cannot block message
    Given Combat is ready
    And the block player has no block weapon
    When the SimpleBlockCommand action is invoked
    Then the block player should see "You are not wielding a weapon you can block with."

  # --- Target is self ---
  Scenario: Targeting self outputs cannot block yourself
    Given Combat is ready
    And the block player has a block weapon
    And the block target is the player themselves
    When the SimpleBlockCommand action is invoked
    Then the block player should see "You cannot block yourself."

  # --- Explicit target, but no blockable events ---
  Scenario: Explicit target with no blockable events outputs what are you trying to block
    Given Combat is ready
    And the block player has a block weapon
    And the block target is "enemy"
    And there are no blockable events for the target
    When the SimpleBlockCommand action is invoked
    Then the block player should see "What are you trying to block?"

  # --- No target at all, no blockable events ---
  Scenario: No target and no blockable events outputs what are you trying to block
    Given Combat is ready
    And the block player has a block weapon
    And there is no block target
    And there are no general blockable events
    When the SimpleBlockCommand action is invoked
    Then the block player should see "What are you trying to block?"

  # --- Explicit target, blockable events exist, rand > 0.5 (weapon block) ---
  Scenario: Successful block with explicit target and rand above 0.5 triggers weapon_block
    Given Combat is ready
    And the block player has a block weapon
    And the block target is "enemy"
    And there are blockable events for the target
    And rand will return above 0.5
    When the SimpleBlockCommand action is invoked
    Then the block event action should be :weapon_block
    And the block event to_other should contain "deftly blocks"
    And the block event to_player on b_event should contain "deftly blocks your attack"
    And the block event to_target on b_event should contain "You deftly block"
    And the block command to_other should contain "raises"
    And the block command to_target should contain "to block your attack"
    And the block command to_player should contain "You raise your"
    And the block player balance should be false
    And the block room should receive out_event

  # --- Explicit target, blockable events exist, rand <= 0.5 (no weapon_block) ---
  Scenario: Successful block with explicit target and rand at or below 0.5 skips weapon_block
    Given Combat is ready
    And the block player has a block weapon
    And the block target is "enemy"
    And there are blockable events for the target
    And rand will return at or below 0.5
    When the SimpleBlockCommand action is invoked
    And the block command to_other should contain "raises"
    And the block command to_target should contain "to block your attack"
    And the block command to_player should contain "You raise your"
    And the block player balance should be false
    And the block room should receive out_event

  # --- No explicit target, falls back to last_target ---
  Scenario: No explicit target falls back to last_target and finds blockable events
    Given Combat is ready
    And the block player has a block weapon
    And there is no block target
    And the player has a last_target of "enemy"
    And there are blockable events for the target
    And rand will return at or below 0.5
    When the SimpleBlockCommand action is invoked
    And the block command to_other should contain "raises"
    And the block player balance should be false
    And the block room should receive out_event

  # --- No target resolved at all, but general blockable events found (target from selfs) ---
  Scenario: No target resolved but general blockable events set target from event player
    Given Combat is ready
    And the block player has a block weapon
    And there is no block target
    And the player has no last_target
    And there are general blockable events with an attacker
    And rand will return at or below 0.5
    When the SimpleBlockCommand action is invoked
    Then the block player last_target should be set to the attacker goid
    And the block command to_other should contain "raises"
    And the block player balance should be false
    And the block room should receive out_event
