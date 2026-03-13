Feature: OpenCommand action
  In order to let players open objects such as doors and chests
  As a maintainer of the Aethyr engine
  I want OpenCommand#action to correctly handle all open scenarios.

  Background:
    Given a stubbed OpenCommand environment

  # --- Object not found (lines 9, 14-16, 18-19) ------------------------------
  Scenario: Opening an object that does not exist
    Given the open target object is not found
    When the OpenCommand action is invoked
    Then the open player should see "Open what?"

  # --- Object cannot be opened (lines 9, 14-16, 20-21) -----------------------
  Scenario: Opening an object that does not support open
    Given an open target object "statue" that cannot be opened
    When the OpenCommand action is invoked
    Then the open player should see "You cannot open statue."

  # --- Object supports open and open succeeds (lines 9, 14-16, 23) -----------
  Scenario: Successfully opening an openable object
    Given an open target object "chest" that can be opened
    When the OpenCommand action is invoked
    Then the open target object should have received open
