Feature: ByeHandler input parsing
  In order to ensure the ByeHandler correctly routes player input to the right command
  As a maintainer of the Aethyr engine
  I want the ByeHandler player_input method to parse bye commands and dispatch the correct actions.

  Background:
    Given a stubbed ByeHandler input environment

  Scenario: "bye" with no arguments dispatches a ByeCommand with nil object and nil post
    When the bye handler input is "bye"
    Then the bye handler should have submitted 1 action
    And the submitted bye handler action should be a ByeCommand
    And the submitted bye handler action object should be nil
    And the submitted bye handler action post should be nil

  Scenario: "bye Bob" dispatches a ByeCommand with object "Bob"
    When the bye handler input is "bye Bob"
    Then the bye handler should have submitted 1 action
    And the submitted bye handler action should be a ByeCommand
    And the submitted bye handler action object should be "Bob"
    And the submitted bye handler action post should be nil

  Scenario: "BYE" uppercase dispatches a ByeCommand
    When the bye handler input is "BYE"
    Then the bye handler should have submitted 1 action
    And the submitted bye handler action should be a ByeCommand

  Scenario: "bye Alice (cheerfully)" dispatches a ByeCommand with object and post
    When the bye handler input is "bye Alice (cheerfully)"
    Then the bye handler should have submitted 1 action
    And the submitted bye handler action should be a ByeCommand
    And the submitted bye handler action object should be "Alice"
    And the submitted bye handler action post should be "(cheerfully)"

  Scenario: Non-matching input does not submit any action
    When the bye handler input is "hello everyone"
    Then the bye handler should have submitted 0 actions
