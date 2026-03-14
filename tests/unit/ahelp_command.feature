Feature: AhelpCommand action
  In order to provide admin help to players
  As a maintainer of the Aethyr engine
  I want AhelpCommand#action to look up the room and delegate to Generic.help.

  Background:
    Given a stubbed ahelp_cmd environment

  # --- constructor (line 8-9) -------------------------------------------------
  Scenario: AhelpCommand can be instantiated
    Then the ahelp_cmd should be instantiated successfully

  # --- action delegates to Generic.help (lines 15-17) -------------------------
  Scenario: Action retrieves the room and calls Generic.help
    When the ahelp_cmd action is invoked
    Then the ahelp_cmd Generic.help should have been called
    And the ahelp_cmd Generic.help should have received the player
    And the ahelp_cmd Generic.help should have received the room
