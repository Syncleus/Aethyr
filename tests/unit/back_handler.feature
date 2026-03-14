Feature: BackHandler input parsing
  In order to ensure the BackHandler correctly routes player input to BackCommand
  As a maintainer of the Aethyr engine
  I want the BackHandler player_input method to parse back commands and dispatch the correct actions.

  Background:
    Given a stubbed BackHandler input environment

  Scenario: back with no target submits a BackCommand
    When the back handler input is "back"
    Then the back handler should have submitted 1 action
    And the submitted back action object should be nil
    And the submitted back action post should be nil

  Scenario: back with a target submits a BackCommand with object
    When the back handler input is "back Bob"
    Then the back handler should have submitted 1 action
    And the submitted back action object should be "Bob"
    And the submitted back action post should be nil

  Scenario: back with a target and post submits a BackCommand with object and post
    When the back handler input is "back Bob (cheerfully)"
    Then the back handler should have submitted 1 action
    And the submitted back action object should be "Bob"
    And the submitted back action post should be "(cheerfully)"

  Scenario: Non-matching input does not submit any action
    When the back handler input is "look around"
    Then the back handler should have submitted 0 actions
