Feature: SkipCommand action
  As a developer of the Aethyr engine
  I want SkipCommand#action to produce the correct emote messages
  So that players can skip with no target, at themselves, or at others.

  Background: 
    Given a stubbed emote commands environment

  Scenario: Skip with no target
    When the SkipCommand action is invoked with no target
    Then the emcmd player should see "You skip around cheerfully."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer skips around cheerfully."

  Scenario: Skip targeting self
    When the SkipCommand action is invoked targeting self
    Then the emcmd player direct output should include "How?"
    And the emcmd room should not have received an event

  Scenario: Skip targeting another
    Given an emcmd target named "Bob" exists in the room
    When the SkipCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You skip around Bob cheerfully."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer skips around you cheerfully."
    And the emcmd event to_other should be "TestPlayer skips around Bob cheerfully."
