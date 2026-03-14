Feature: CheerHandler input parsing
  In order to ensure the CheerHandler correctly routes player input to CheerCommand
  As a maintainer of the Aethyr engine
  I want the CheerHandler player_input method to parse cheer commands and dispatch the correct actions.

  Background:
    Given a stubbed CheerHandler input environment

  Scenario: cheer with no target submits a CheerCommand
    When the cheer handler input is "cheer"
    Then the cheer handler should have submitted 1 action
    And the submitted cheer action object should be nil
    And the submitted cheer action post should be nil

  Scenario: cheer with a target submits a CheerCommand with object
    When the cheer handler input is "cheer Bob"
    Then the cheer handler should have submitted 1 action
    And the submitted cheer action object should be "Bob"
    And the submitted cheer action post should be nil

  Scenario: cheer with a target and post submits a CheerCommand with object and post
    When the cheer handler input is "cheer Bob (cheerfully)"
    Then the cheer handler should have submitted 1 action
    And the submitted cheer action object should be "Bob"
    And the submitted cheer action post should be "(cheerfully)"

  Scenario: Non-matching input does not submit any action
    When the cheer handler input is "look around"
    Then the cheer handler should have submitted 0 actions
