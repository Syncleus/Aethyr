Feature: Lever game objects
  A Lever is a custom-action GameObject used for interactive objects
  that support the "pull" action.

  Scenario: Creating a Lever with default arguments
    Given I require the Lever library
    When I create a new Lever with default arguments
    Then the Lever name should be "lever"
    And the Lever generic should be "lever"
    And the Lever short_desc should be "lever"
    And the Lever should be a kind of GameObject

  Scenario: Lever has a descriptive long description
    Given I require the Lever library
    When I create a new Lever with default arguments
    Then the Lever long_desc should describe a 2 foot lever with a grip

  Scenario: Lever supports the pull action
    Given I require the Lever library
    When I create a new Lever with default arguments
    Then the Lever actions should include "pull"
