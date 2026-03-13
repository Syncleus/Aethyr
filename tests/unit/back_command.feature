Feature: BackCommand action
  As a developer of the Aethyr engine
  I want BackCommand#action to produce the correct emote messages
  So that players can back with no target, at themselves, or at others.

  Background: 
    Given a stubbed emote commands environment

  Scenario: Back with no target
    When the BackCommand action is invoked with no target
    Then the emcmd player should see "\"I'm back!\" you happily announce."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "\"I'm back!\" TestPlayer happily announces to those nearby."

  Scenario: Back targeting self
    When the BackCommand action is invoked targeting self
    Then the emcmd player direct output should include "Hm? How do you do that?"
    And the emcmd room should not have received an event

  Scenario: Back targeting another
    Given an emcmd target named "Bob" exists in the room
    When the BackCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You happily announce your return to Bob."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer happily announces his return to you."
    And the emcmd event to_other should be "TestPlayer announces his return to Bob."
