Feature: CloseCommand action
  In order to let players close objects such as doors and chests
  As a maintainer of the Aethyr engine
  I want CloseCommand#action to correctly handle all close scenarios.

  Background:
    Given a stubbed CloseCommand environment

  # --- Object not found (lines 9, 14-16, 18-19) ------------------------------
  Scenario: Closing an object that does not exist
    Given the close target object is not found
    When the CloseCommand action is invoked
    Then the close player should see "Close what?"

  # --- Object cannot be opened/closed (lines 9, 14-16, 20-21) ----------------
  Scenario: Closing an object that does not support open
    Given a close target object "statue" that cannot be opened
    When the CloseCommand action is invoked
    Then the close player should see "You cannot close statue."

  # --- Object supports open and close succeeds (lines 9, 14-16, 23) ----------
  Scenario: Successfully closing an openable object
    Given a close target object "chest" that can be opened
    When the CloseCommand action is invoked
    Then the close target object should have received close
