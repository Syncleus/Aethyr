Feature: Openable trait for game objects
  The Openable module provides open, close, lock, and unlock behaviour
  to game objects such as chests and doors.

  # -------------------------------------------------------------------
  # Initialisation & query helpers
  # -------------------------------------------------------------------
  Scenario: Openable object initialises with sensible defaults
    Given an openable object
    Then the openable object should not be open
    And the openable object should be closed
    And the openable object should not be locked
    And the openable object should not be lockable
    And the openable object should report openable as true
    And the openable object keys should be empty

  # -------------------------------------------------------------------
  # Opening
  # -------------------------------------------------------------------
  Scenario: Opening a closed and unlocked object with a name
    Given an openable object with name "Treasure Chest"
    When the openable object is opened by "Alice"
    Then the openable object should be open
    And the openable object should not be closed
    And the openable player output should include "You open Treasure Chest"
    And the openable room output should include "Alice opens Treasure Chest"

  Scenario: Opening a closed and unlocked object without a name
    Given an openable object with no name
    When the openable object is opened by "Bob"
    Then the openable object should be open
    And the openable player output should include "You open a chest"
    And the openable room output should include "Bob opens a chest"

  Scenario: Opening an already-open object
    Given an openable object that is already open
    When the openable object is opened by "Alice"
    Then the openable player output should include "already open"

  Scenario: Opening a locked object
    Given an openable object that is locked
    When the openable object is opened by "Alice"
    Then the openable player output should include "is locked"
    And the openable object should not be open

  # -------------------------------------------------------------------
  # Closing
  # -------------------------------------------------------------------
  Scenario: Closing an open object with a name
    Given an openable object with name "Treasure Chest" that is open
    When the openable object is closed by "Alice"
    Then the openable object should not be open
    And the openable object should be closed
    And the openable player output should include "You close Treasure Chest"
    And the openable room output should include "Alice closes Treasure Chest"

  Scenario: Closing an open object without a name
    Given an openable object with no name that is open
    When the openable object is closed by "Bob"
    Then the openable object should not be open
    And the openable player output should include "You close a chest"
    And the openable room output should include "Bob closes a chest"

  Scenario: Closing an already-closed object
    Given an openable object
    When the openable object is closed by "Alice"
    Then the openable player output should include "already closed"

  # -------------------------------------------------------------------
  # Locking
  # -------------------------------------------------------------------
  Scenario: Locking with a valid key
    Given an openable lockable object with key "gold_key"
    When the openable object is locked with key "gold_key"
    Then the openable lock result should be true
    And the openable object should be locked

  Scenario: Locking fails when not lockable
    Given an openable object
    When the openable object is locked with key "gold_key"
    Then the openable lock result should be false

  Scenario: Locking fails when already locked
    Given an openable lockable object with key "gold_key" that is locked
    When the openable object is locked with key "gold_key"
    Then the openable lock result should be false

  Scenario: Locking fails with wrong key
    Given an openable lockable object with key "gold_key"
    When the openable object is locked with key "silver_key"
    Then the openable lock result should be false
    And the openable object should not be locked

  Scenario: Locking with admin bypasses key check
    Given an openable lockable object with key "gold_key"
    When the openable object is locked with admin override
    Then the openable lock result should be true
    And the openable object should be locked

  Scenario: Locking propagates to connected object
    Given an openable lockable object with key "gold_key" connected to another lockable object
    When the openable object is locked with key "gold_key"
    Then the openable lock result should be true
    And the openable connected object should also be locked

  # -------------------------------------------------------------------
  # Unlocking
  # -------------------------------------------------------------------
  Scenario: Unlocking with a valid key
    Given an openable lockable object with key "gold_key" that is locked
    When the openable object is unlocked with key "gold_key"
    Then the openable unlock result should be true
    And the openable object should not be locked

  Scenario: Unlocking fails when not lockable
    Given an openable object
    When the openable object is unlocked with key "gold_key"
    Then the openable unlock result should be false

  Scenario: Unlocking fails when not locked
    Given an openable lockable object with key "gold_key"
    When the openable object is unlocked with key "gold_key"
    Then the openable unlock result should be false

  Scenario: Unlocking fails with wrong key
    Given an openable lockable object with key "gold_key" that is locked
    When the openable object is unlocked with key "silver_key"
    Then the openable unlock result should be false
    And the openable object should be locked

  Scenario: Unlocking with admin bypasses key check
    Given an openable lockable object with key "gold_key" that is locked
    When the openable object is unlocked with admin override
    Then the openable unlock result should be true
    And the openable object should not be locked

  Scenario: Unlocking propagates to connected object
    Given an openable lockable object with key "gold_key" connected to another locked object
    When the openable object is unlocked with key "gold_key"
    Then the openable unlock result should be true
    And the openable connected object should also be unlocked

  # -------------------------------------------------------------------
  # Openable.included hook (look_inside wrapper)
  # -------------------------------------------------------------------
  Scenario: Openable.included wraps look_inside when present
    Given an openable object class with a look_inside method
    When the openable look_inside object is open and look_inside is called
    Then the openable look_inside should delegate to the original method

  Scenario: Openable.included blocks look_inside when closed
    Given an openable object class with a look_inside method
    When the openable look_inside object is closed and look_inside is called
    Then the openable player output should include "open it first"
