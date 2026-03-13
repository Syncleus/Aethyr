Feature: HuhCommand action
  As a developer of the Aethyr engine
  I want HuhCommand#action to produce the correct emote messages
  So that players can express confusion with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Huh with no target
    When the HuhCommand action is invoked with no target
    Then the emcmd player should see "\"Huh?\" you ask, confused."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer ask, \"Huh?\" and looks confused."

  Scenario: Huh targeting self
    When the HuhCommand action is invoked targeting self
    Then the emcmd player direct output should include "Well, huh!"
    And the emcmd room should not have received an event

  Scenario: Huh targeting another
    Given an emcmd target named "Bob" exists in the room
    When the HuhCommand action is invoked targeting "Bob"
    Then the emcmd player should see "\"Huh?\" you ask Bob."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer asks, \"Huh?\""
    And the emcmd event to_other should be "TestPlayer asks Bob, \"Huh?\""
