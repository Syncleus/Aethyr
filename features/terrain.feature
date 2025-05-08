Feature: Terrain metadata
  Terrain constants expose user-friendly text for rooms and areas.

  Scenario: Grassland terrain strings are correct
    Given I require the Terrain library
    When I retrieve the GRASSLAND terrain descriptor
    Then the room text should be "part of the grasslands"
    And the area text should be "waving grasslands"
    And the terrain name should be "grasslands"
