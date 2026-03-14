Feature: Chair game objects
  A Chair is a GameObject that includes the Sittable trait
  and provides seating in the game world.

  Scenario: Creating a Chair with default arguments
    Given I require the Chair library
    When I create a new Chair with default arguments
    Then the Chair name should be "a nice chair"
    And the Chair generic should be "chair"
    And the Chair should not be movable
    And the Chair should be a kind of GameObject
    And the Chair should be sittable
