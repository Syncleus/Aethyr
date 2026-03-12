Feature: Weapon objects
  Sword and other weapon subclasses initialise with correct combat attributes.

  Scenario: Sword initialises with correct default attributes
    Given I require the Sword weapon library
    When I create a new Sword weapon object
    Then the Sword generic should be "sword"
    And the Sword weapon_type should be :sword
    And the Sword attack should be 10
    And the Sword defense should be 5

  Scenario: Sword inherits Weapon wield position
    Given I require the Sword weapon library
    When I create a new Sword weapon object
    Then the Sword position should be :wield
    And the Sword should be movable

  Scenario: Sword is an instance of Weapon
    Given I require the Sword weapon library
    When I create a new Sword weapon object
    Then the Sword should be a kind of Weapon
    And the Sword layer should be 0
