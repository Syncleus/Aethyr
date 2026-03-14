Feature: Armor objects
  Armor initialises with correct default attributes and includes Wearable.

  Scenario: Armor initialises with correct default attributes
    Given I require the Armor library
    When I create a new Armor object
    Then the Armor generic should be "armor"
    And the Armor article should be "a suit of"
    And the Armor should be movable
    And the Armor condition should be 100

  Scenario: Armor has correct Wearable layer and position
    Given I require the Armor library
    When I create a new Armor object
    Then the Armor layer should be 1
    And the Armor position should be :torso

  Scenario: Armor is an instance of GameObject and includes Wearable
    Given I require the Armor library
    When I create a new Armor object
    Then the Armor should be a kind of GameObject
