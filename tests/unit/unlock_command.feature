Feature: UnlockCommand action
  In order to let players unlock lockable objects
  As a maintainer of the Aethyr engine
  I want UnlockCommand#action to correctly handle all unlock scenarios.

  Background:
    Given a stubbed UnlockCommand environment

  # --- Object not found (lines 9, 14-15, 17-19) ----------------------------
  Scenario: Unlocking an object that does not exist
    Given the unlock object is not found
    When the UnlockCommand action is invoked
    Then the unlock player should see "Unlock what?"

  # --- Object cannot be unlocked (lines 14-15, 20-22) ----------------------
  Scenario: Unlocking an object that cannot be unlocked
    Given an unlock target object "rock" that cannot be unlocked
    When the UnlockCommand action is invoked
    Then the unlock player should see "That object cannot be unlocked."

  # --- Object is already unlocked (lines 14-15, 23-25) ---------------------
  Scenario: Unlocking an object that is already unlocked
    Given an unlock target object "chest" that is already unlocked
    When the UnlockCommand action is invoked
    Then the unlock player should see "is already unlocked"

  # --- No key for the object (lines 14-15, 28-34, 60-61) -------------------
  Scenario: Unlocking without having the key
    Given an unlock target object "chest" that is locked with key "gold_key"
    And the unlock player does not have the key
    When the UnlockCommand action is invoked
    Then the unlock player should see "You do not have the key"

  # --- Has key, successful unlock (lines 14-15, 28-32, 36-43, 54) ----------
  Scenario: Successfully unlocking with a key
    Given an unlock target object "chest" that is locked with key "gold_key"
    And the unlock player has the key "gold_key"
    When the UnlockCommand action is invoked
    Then the unlock room should have an out_event with to_player "You unlock chest."
    And the unlock room should have an out_event with to_other "TestPlayer unlocks chest."

  # --- Admin override, successful unlock (lines 14-15, 28-34, 36-43, 54) ---
  Scenario: Admin can unlock without a key
    Given an unlock target object "chest" that is locked with key "gold_key"
    And the unlock player is an admin
    When the UnlockCommand action is invoked
    Then the unlock room should have an out_event with to_player "You unlock chest."
    And the unlock room should have an out_event with to_other "TestPlayer unlocks chest."

  # --- Unlock returns false (lines 14-15, 28-32, 36-37, 56-57) -------------
  Scenario: Unlock fails even with a key
    Given an unlock target object "chest" that is locked with key "gold_key" but unlock fails
    And the unlock player has the key "gold_key"
    When the UnlockCommand action is invoked
    Then the unlock player should see "You are unable to unlock"

  # --- Door with connected side (lines 14-15, 28-32, 36-43, 45-51, 54) -----
  Scenario: Unlocking a connected door propagates to other side
    Given an unlock target door "wooden door" that is locked with key "iron_key" and connected
    And the unlock player has the key "iron_key"
    When the UnlockCommand action is invoked
    Then the unlock room should have an out_event with to_player "You unlock wooden door."
    And the unlock other side should have been unlocked
    And the unlock other room should have an out_event
