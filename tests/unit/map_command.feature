Feature: MapCommand action
  In order to let players view a map of their current area
  As a maintainer of the Aethyr engine
  I want MapCommand#action to render the area map for the player.

  Background:
    Given a stubbed MapCommand environment

  Scenario: Displays the area map to the player
    When the MapCommand action is invoked
    Then the map command player should see "rendered map output"
