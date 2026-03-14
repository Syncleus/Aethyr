Feature: AputHandler input parsing
  In order to ensure the AputHandler correctly routes admin input to AputCommand
  As a maintainer of the Aethyr engine
  I want the AputHandler player_input method to parse aput commands.

  Background:
    Given a stubbed AputHandler input environment

  # --- "aput <object> in <container> at <position>" branch (lines 38-42) ---
  Scenario: aput with object, container and at parameter submits an AputCommand
    When the aput handler input is "aput gem in chest at 3x5"
    Then the aput handler should have submitted 1 action
    And the submitted aput action should have object "gem"
    And the submitted aput action should have in "chest"
    And the submitted aput action should have at "3x5"

  Scenario: aput with multi-word object and container and at parameter
    When the aput handler input is "aput shiny gem in big chest at 2x4"
    Then the aput handler should have submitted 1 action
    And the submitted aput action should have object "shiny gem"
    And the submitted aput action should have in "big chest"
    And the submitted aput action should have at "2x4"

  Scenario: aput with at parameter is case-insensitive
    When the aput handler input is "APUT sword IN box AT 1x1"
    Then the aput handler should have submitted 1 action
    And the submitted aput action should have object "sword"
    And the submitted aput action should have in "box"
    And the submitted aput action should have at "1x1"

  # --- "aput <object> in <container>" branch (lines 43-46) ---
  Scenario: aput with object and container submits an AputCommand
    When the aput handler input is "aput gem in chest"
    Then the aput handler should have submitted 1 action
    And the submitted aput action should have object "gem"
    And the submitted aput action should have in "chest"

  Scenario: aput with multi-word object and container
    When the aput handler input is "aput rusty sword in old chest"
    Then the aput handler should have submitted 1 action
    And the submitted aput action should have object "rusty sword"
    And the submitted aput action should have in "old chest"

  Scenario: aput without at parameter is case-insensitive
    When the aput handler input is "APUT gem IN chest"
    Then the aput handler should have submitted 1 action
    And the submitted aput action should have object "gem"
    And the submitted aput action should have in "chest"

  # --- Non-matching input does not submit ---
  Scenario: Non-matching input does not submit any action
    When the aput handler input is "look around"
    Then the aput handler should have submitted 0 actions
