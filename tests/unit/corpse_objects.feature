Feature: Corpse game objects
  A Corpse is left behind when something dies. It includes the Expires
  trait and automatically decomposes after a set period.

  Scenario: Creating a Corpse with default arguments
    Given I require the Corpse library
    When I create a new Corpse with default arguments
    Then the Corpse generic should be "corpse"
    And the Corpse should be a kind of GameObject
    And the Corpse should be movable
    And the Corpse long_desc should be "A smelly, rapidly decomposing corpse. Yuck."
    And the Corpse should have an expiration time set

  Scenario: Corpse includes the Expires trait
    Given I require the Corpse library
    When I create a new Corpse with default arguments
    Then the Corpse should include the Expires module

  Scenario: Making a corpse of a named mobile
    Given I require the Corpse library
    And I create a new Corpse with default arguments
    When I make the Corpse the corpse of a mobile named "goblin" with generic "goblin" and alt_names "greenskin,monster"
    Then the Corpse name should be "corpse of goblin"
    And the Corpse alt_names should include "goblin"
    And the Corpse alt_names should include "greenskin"
    And the Corpse alt_names should include "monster"
    And the Corpse long_desc should be "This is the empty and rapidly decomposing shell of goblin."

  Scenario: Making a corpse of a mobile with no alt_names
    Given I require the Corpse library
    And I create a new Corpse with default arguments
    When I make the Corpse the corpse of a mobile named "rat" with generic "rat" and no alt_names
    Then the Corpse name should be "corpse of rat"
    And the Corpse alt_names should include "rat"
    And the Corpse long_desc should be "This is the empty and rapidly decomposing shell of rat."
