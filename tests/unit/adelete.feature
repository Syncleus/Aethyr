Feature: AdeleteCommand action
  In order to let admins remove game objects at runtime
  As a maintainer of the Aethyr engine
  I want AdeleteCommand#action to correctly delete objects from the game world.

  Background:
    Given a stubbed AdeleteCommand environment

  # --- constructor (line 9) ---------------------------------------------------
  Scenario: AdeleteCommand can be instantiated
    Then the AdeleteCommand should be instantiated successfully

  # --- "delete all <class>" with valid class (lines 15-20, 22, 28, 30-32, 34, 37)
  Scenario: Deleting all objects of a valid class
    Given the adelete object reference is "all String"
    When the AdeleteCommand action is invoked
    Then Admin.adelete should have been called for adelete

  # --- "delete all <class>" with invalid class (lines 15-20, 22, 24-25) -------
  Scenario: Deleting all objects of an unknown class produces an error
    Given the adelete object reference is "all Xyzzynonexistent"
    When the AdeleteCommand action is invoked
    Then the adelete player should see "No such object type."

  # --- object not found (lines 40, 42-44) -------------------------------------
  Scenario: Object not found produces an error message
    Given the adelete object reference is "nonexistent_goid"
    And adelete find_object will return nil
    When the AdeleteCommand action is invoked
    Then the adelete player should see "Cannot find nonexistent_goid to delete."

  # --- object is a Player (lines 40, 45-47) -----------------------------------
  Scenario: Deleting a Player object produces an error message
    Given the adelete object is a Player
    When the AdeleteCommand action is invoked
    Then the adelete player should see "Use the DELETEPLAYER command to delete other players."

  # --- object deleted, same room (lines 40, 50, 52, 54-57, 62) ----------------
  Scenario: Deleting an object in the same room broadcasts to room
    Given the adelete object is in the same room
    When the AdeleteCommand action is invoked
    Then the adelete room should receive the event
    And the adelete player should see "deleted."

  # --- object deleted, different room (lines 40, 50, 52, 59, 62) --------------
  Scenario: Deleting an object in a different room outputs only to player
    Given the adelete object is in a different room
    When the AdeleteCommand action is invoked
    Then the adelete player should see "disappears."
    And the adelete player should see "deleted."

  # --- "delete all" with lowercase class that gets capitalized (line 20) ------
  Scenario: Deleting all with lowercase class name capitalizes it
    Given the adelete object reference is "all string"
    When the AdeleteCommand action is invoked
    Then Admin.adelete should have been called for adelete
