Feature: Agree emote input handler
  In order to express agreement using natural commands
  As a player
  I want the AgreeHandler to translate my textual input into the correct AgreeCommand objects.

  Background:
    Given a stubbed AgreeHandler environment

  Scenario: Agree with no target
    When the agree handler receives input "agree"
    Then the manager should receive an AgreeCommand
    And the AgreeCommand should have no object
    And the AgreeCommand should have no post

  Scenario: Agree targeting another player
    When the agree handler receives input "agree Bob"
    Then the manager should receive an AgreeCommand
    And the AgreeCommand object should be "Bob"
    And the AgreeCommand should have no post

  Scenario: Agree targeting another player with post text
    When the agree handler receives input "agree Bob (nodding)"
    Then the manager should receive an AgreeCommand
    And the AgreeCommand object should be "Bob"
    And the AgreeCommand post should be "(nodding)"

  Scenario: Input that does not match agree
    When the agree handler receives input "disagree"
    Then the agree handler manager should not receive any action
