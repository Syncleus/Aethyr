Feature: Prop game objects
  A Prop is a basic GameObject used for simple in-game objects
  that do not need any special properties.

  Scenario: Creating a Prop with default arguments
    Given I require the Prop library
    When I create a new Prop with default arguments
    Then the Prop generic should be "prop"
    And the Prop should be a kind of GameObject

  Scenario: Creating a Prop with a custom name
    Given I require the Prop library
    When I create a new Prop with name "wooden chair"
    Then the Prop generic should be "prop"
    And the Prop name should be "wooden chair"

  Scenario: Prop inherits GameObject attributes
    Given I require the Prop library
    When I create a new Prop with default arguments
    Then the Prop should have a game object id
    And the Prop should not be movable
    And the Prop quantity should be 1
