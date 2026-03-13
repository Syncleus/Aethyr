Feature: WaveCommand action
  As a developer of the Aethyr engine
  I want WaveCommand#action to produce the correct emote messages
  So that players can wave with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Wave with no target
    When the WaveCommand action is invoked with no target
    Then the emcmd player should see "You wave goodbye to everyone."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer waves goodbye to everyone."

  Scenario: Wave targeting self
    When the WaveCommand action is invoked targeting self
    Then the emcmd player direct output should include "Waving at someone?"
    And the emcmd room should not have received an event

  Scenario: Wave targeting another
    Given an emcmd target named "Bob" exists in the room
    When the WaveCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You wave farewell to Bob."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer waves farewell to you."
    And the emcmd event to_other should be "TestPlayer waves farewell to Bob."
