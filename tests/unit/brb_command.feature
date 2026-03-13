Feature: BrbCommand action
  As a developer of the Aethyr engine
  I want BrbCommand#action to produce the correct emote messages
  So that players can brb with no target, at themselves, or at others.

  Background: 
    Given a stubbed emote commands environment

  Scenario: Brb with no target
    When the BrbCommand action is invoked with no target
    Then the emcmd player should see "\"I shall return shortly!\" you say to no one in particular."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer says, \"I shall return shortly!\" to no one in particular."

  Scenario: Brb targeting self
    When the BrbCommand action is invoked targeting self
    Then the emcmd player direct output should include "Hm? How do you do that?"
    And the emcmd room should not have received an event

  Scenario: Brb targeting another
    Given an emcmd target named "Bob" exists in the room
    When the BrbCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You let Bob know you will return shortly."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer lets you know he will return shortly."
    And the emcmd event to_other should be "TestPlayer tells Bob that he will return shortly."
