Feature: Cry emote input handler
  In order to express sadness through natural commands
  As a player
  I want the CryHandler to translate my textual input into the correct CryCommand objects.

  Background:
    Given a stubbed CryHandler environment

  Scenario: Cry with no target and no post
    When the cry player enters "cry"
    Then the cry manager should receive a CryCommand
    And the CryCommand object should be nil
    And the CryCommand post should be nil

  Scenario: Cry with a target
    When the cry player enters "cry Bob"
    Then the cry manager should receive a CryCommand
    And the CryCommand object should be "Bob"
    And the CryCommand post should be nil

  Scenario: Cry with a target and post
    When the cry player enters "cry Bob (sobbing loudly)"
    Then the cry manager should receive a CryCommand
    And the CryCommand object should be "Bob"
    And the CryCommand post should be "(sobbing loudly)"

  Scenario: Non-matching input does not produce a CryCommand
    When the cry player enters "laugh"
    Then the cry manager should not receive any action
