Feature: RestartCommand action
  In order to let admins restart the game server
  As a maintainer of the Aethyr engine
  I want RestartCommand#action to invoke $manager.restart correctly.

  Background:
    Given a stubbed RestartCommand environment

  # --- Lines 15-17: action body executes fully --------------------------------
  Scenario: Restart command calls manager restart
    When the RestartCommand action is invoked
    Then the restart manager should have resolved the room
    And the restart manager restart should have been called
