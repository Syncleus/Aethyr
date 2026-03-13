Feature: AhideCommand action
  In order to let admins hide and unhide game objects
  As a maintainer of the Aethyr engine
  I want AhideCommand#action to correctly toggle show_in_look on game objects.

  Background:
    Given a stubbed ahide_cmd environment

  # --- constructor (line 9) ---------------------------------------------------
  Scenario: AhideCommand can be instantiated
    Then the ahide_cmd should be instantiated successfully

  # --- object not found (lines 19-21) ----------------------------------------
  Scenario: Object not found produces an error message
    Given the ahide_cmd object reference is "ghost"
    And ahide_cmd find_object returns nil
    When the ahide_cmd action is invoked
    Then the ahide_cmd player should see "Cannot find ghost."

  # --- hide object (lines 24-26) ---------------------------------------------
  Scenario: Hiding an object sets show_in_look to empty string
    Given the ahide_cmd object reference is "sword"
    And ahide_cmd find_object returns an object named "Rusty Sword"
    And ahide_cmd hide is true
    When the ahide_cmd action is invoked
    Then the ahide_cmd object show_in_look should be ""
    And the ahide_cmd player should see "Rusty Sword is now hidden."

  # --- unhide object currently hidden (lines 27-29) --------------------------
  Scenario: Unhiding a hidden object sets show_in_look to false
    Given the ahide_cmd object reference is "sword"
    And ahide_cmd find_object returns an object named "Rusty Sword" with show_in_look ""
    And ahide_cmd hide is not set
    When the ahide_cmd action is invoked
    Then the ahide_cmd object show_in_look should be false
    And the ahide_cmd player should see "Rusty Sword is no longer hidden."

  # --- object is not hidden (line 31) ----------------------------------------
  Scenario: Unhiding an object that is not hidden produces an error
    Given the ahide_cmd object reference is "sword"
    And ahide_cmd find_object returns an object named "Rusty Sword" with show_in_look "visible"
    And ahide_cmd hide is not set
    When the ahide_cmd action is invoked
    Then the ahide_cmd player should see "This object is not hidden."
