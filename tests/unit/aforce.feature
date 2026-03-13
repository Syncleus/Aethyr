Feature: AforceCommand action
  In order to let admins force other players to execute commands
  As a maintainer of the Aethyr engine
  I want AforceCommand#action to correctly validate force targets.

  Background:
    Given a stubbed AforceCommand environment

  # --- constructor (line 9) + target not found (lines 15-20) ------------------
  Scenario: Target not found produces error message
    Given the aforce target is "nonexistent_goid"
    And aforce find_object will return nil
    When the AforceCommand action is invoked
    Then the aforce player should see "Force who?"

  # --- target is a Player (lines 15-17, 21-23) --------------------------------
  Scenario: Forcing a Player object produces error message
    Given the aforce target object is a Player
    When the AforceCommand action is invoked
    Then the aforce player should see "Cannot force another player."

  # --- target is a non-Player object (lines 15-17, 25) ------------------------
  Scenario: Forcing a non-Player object produces error message
    Given the aforce target object is a non-Player
    When the AforceCommand action is invoked
    Then the aforce player should see "You can only force other players to execute a command."
