Feature: Dagger objects
  Dagger weapon subclass initialises with correct combat attributes.

  Scenario: Dagger initialises with correct default attributes
    Given I require the Dagger weapon library
    When I create a new Dagger weapon object
    Then the Dagger generic should be "dagger"
    And the Dagger weapon_type should be :dagger
    And the Dagger attack should be 5
    And the Dagger defense should be 5

  Scenario: Dagger inherits Weapon wield position
    Given I require the Dagger weapon library
    When I create a new Dagger weapon object
    Then the Dagger position should be :wield
    And the Dagger should be movable

  Scenario: Dagger is an instance of Weapon
    Given I require the Dagger weapon library
    When I create a new Dagger weapon object
    Then the Dagger should be a kind of Weapon
    And the Dagger layer should be 0
