Feature: AlearnCommand action
  In order to let admins manage learning on game objects
  As a maintainer of the Aethyr engine
  I want AlearnCommand to initialize correctly and execute its action.

  Background:
    Given a stubbed alearn_cmd environment

  # --- constructor (line 9) ---------------------------------------------------
  Scenario: AlearnCommand can be instantiated
    Then the alearn_cmd should be instantiated successfully

  # --- action (lines 15-16) ---------------------------------------------------
  Scenario: AlearnCommand action retrieves room and player
    When the alearn_cmd action is invoked
    Then the alearn_cmd action should complete without error
