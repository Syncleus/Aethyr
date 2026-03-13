Feature: ByeCommand action
  As a developer of the Aethyr engine
  I want ByeCommand#action to produce the correct emote messages
  So that players can bye with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Bye with no target
    When the ByeCommand action is invoked with no target
    Then the emcmd player should see "You say a hearty \"Goodbye!\" to those around you."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer says a hearty \"Goodbye!\""

  Scenario: Bye targeting self
    When the ByeCommand action is invoked targeting self
    Then the emcmd player direct output should include "Goodbye."
    And the emcmd room should not have received an event

  Scenario: Bye targeting another
    Given an emcmd target named "Bob" exists in the room
    When the ByeCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You say \"Goodbye!\" to Bob."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer says \"Goodbye!\" to you."
    And the emcmd event to_other should be "TestPlayer says \"Goodbye!\" to Bob"
