Feature: Blush emote input handler
  In order to express embarrassment in the game world
  As a player
  I want the BlushHandler to translate my textual input into the correct BlushCommand objects.

  Background:
    Given a stubbed BlushHandler environment

  Scenario: Blush with no target and no post
    When the blush handler receives input "blush"
    Then the manager should receive a BlushCommand
    And the BlushCommand should have no object
    And the BlushCommand should have no post

  Scenario: Blush targeting another player
    When the blush handler receives input "blush Bob"
    Then the manager should receive a BlushCommand
    And the BlushCommand object should be "Bob"
    And the BlushCommand should have no post

  Scenario: Blush targeting another player with a post
    When the blush handler receives input "blush Bob (sheepishly)"
    Then the manager should receive a BlushCommand
    And the BlushCommand object should be "Bob"
    And the BlushCommand post should be "(sheepishly)"
