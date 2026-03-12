Feature: LockCommand action
  In order to let players lock objects such as doors and chests
  As a maintainer of the Aethyr engine
  I want LockCommand#action to correctly handle all lock scenarios.

  Background:
    Given a stubbed LockCommand environment

  # --- Object not found (lines 14-15, 17-19) ---------------------------------
  Scenario: Locking an object that does not exist
    Given the lock target object is not found
    When the LockCommand action is invoked
    Then the lock player should see "Lock what?"

  # --- Object cannot be locked (lines 14-15, 20-22) --------------------------
  Scenario: Locking an object that cannot be locked
    Given a lock target object "statue" that cannot be locked
    When the LockCommand action is invoked
    Then the lock player should see "That object cannot be locked."

  # --- Object is already locked (lines 14-15, 23-25) -------------------------
  Scenario: Locking an object that is already locked
    Given a lock target object "chest" that is already locked
    When the LockCommand action is invoked
    Then the lock player should see "chest is already locked."

  # --- No key and not admin (lines 28-32, 57) --------------------------------
  Scenario: Locking without the required key
    Given a lock target object "chest" that is lockable and unlocked with key "gold_key"
    And the lock player does not have the key
    When the LockCommand action is invoked
    Then the lock player should see "You do not have the key to that chest."

  # --- Has key, lock succeeds (lines 28-32, 36-43) ---------------------------
  Scenario: Successfully locking with the correct key
    Given a lock target object "chest" that is lockable and unlocked with key "gold_key"
    And the lock player has key "gold_key" in inventory
    When the LockCommand action is invoked
    Then the lock event to_player should be "You lock chest."
    And the lock event to_other should be "TestLocker locks chest."
    And the lock event to_blind_other should be "You hear the click of a lock."
    And the lock room should have received an event

  # --- Admin override, lock succeeds (lines 36-41, 43) -----------------------
  Scenario: Admin can lock without a key
    Given a lock target object "chest" that is lockable and unlocked with key "gold_key"
    And the lock player is an admin
    When the LockCommand action is invoked
    Then the lock event to_player should be "You lock chest."
    And the lock room should have received an event

  # --- Lock succeeds on a connected Door (lines 45-51) -----------------------
  Scenario: Locking a connected door also locks the other side
    Given a lock target door "oak door" that is lockable and unlocked with key "iron_key"
    And the lock door is connected to another door
    And the lock player has key "iron_key" in inventory
    When the LockCommand action is invoked
    Then the lock event to_player should be "You lock oak door."
    And the lock room should have received an event
    And the lock other side should have been locked
    And the lock other room should have received an event

  # --- Lock returns false (line 54) ------------------------------------------
  Scenario: Lock method returns false
    Given a lock target object "chest" that fails to lock
    And the lock player has key "gold_key" in inventory
    When the LockCommand action is invoked
    Then the lock player should see "You are unable to lock that chest."
