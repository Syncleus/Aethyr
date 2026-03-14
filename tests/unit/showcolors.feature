Feature: ShowcolorsCommand action
  In order to let players view their color configuration
  As a maintainer of the Aethyr engine
  I want ShowcolorsCommand#action to output the player's color config.

  Background:
    Given a stubbed ShowcolorsCommand environment

  Scenario: Action outputs the color configuration to the player
    When the ShowcolorsCommand action is invoked
    Then the showcolors player should see the color config
