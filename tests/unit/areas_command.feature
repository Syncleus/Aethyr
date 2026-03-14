Feature: AreasCommand action
  In order to let admins see all areas in the game
  As a maintainer of the Aethyr engine
  I want AreasCommand#action to list areas with room counts and terrain types.

  Background:
    Given a stubbed AreasCommand environment

  Scenario: No areas exist
    Given the areas manager find_all returns no areas
    When the AreasCommand action is invoked
    Then the areas player should see "There are no areas."

  Scenario: One area exists with rooms
    Given the areas manager find_all returns one area named "Forest" with 3 rooms and terrain "forest"
    When the AreasCommand action is invoked
    Then the areas player should see "Forest"
    And the areas player should see "3 rooms"
    And the areas player should see "forest"

  Scenario: Multiple areas exist
    Given the areas manager find_all returns multiple areas
    When the AreasCommand action is invoked
    Then the areas player should see "Forest"
    And the areas player should see "Desert"
