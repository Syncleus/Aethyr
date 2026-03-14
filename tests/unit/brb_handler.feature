Feature: BrbHandler input parsing
  In order to ensure the BrbHandler correctly routes player input to BrbCommand
  As a maintainer of the Aethyr engine
  I want the BrbHandler player_input method to parse brb commands and dispatch the correct actions.

  Background:
    Given a stubbed BrbHandler input environment

  Scenario: "brb" with no target submits a BrbCommand with nil object and nil post
    When the brb handler input is "brb"
    Then the brb handler should have submitted 1 action
    And the submitted brb handler action should be a BrbCommand
    And the submitted brb handler action object should be nil
    And the submitted brb handler action post should be nil

  Scenario: "BRB" uppercase also submits a BrbCommand
    When the brb handler input is "BRB"
    Then the brb handler should have submitted 1 action
    And the submitted brb handler action should be a BrbCommand

  Scenario: "brb Bob" submits a BrbCommand with object "Bob"
    When the brb handler input is "brb Bob"
    Then the brb handler should have submitted 1 action
    And the submitted brb handler action should be a BrbCommand
    And the submitted brb handler action object should be "Bob"
    And the submitted brb handler action post should be nil

  Scenario: "brb someone (waving)" submits a BrbCommand with object and post
    When the brb handler input is "brb someone (waving)"
    Then the brb handler should have submitted 1 action
    And the submitted brb handler action should be a BrbCommand
    And the submitted brb handler action object should be "someone"
    And the submitted brb handler action post should be "(waving)"

  Scenario: Non-matching input does not submit any action
    When the brb handler input is "look around"
    Then the brb handler should have submitted 0 actions
