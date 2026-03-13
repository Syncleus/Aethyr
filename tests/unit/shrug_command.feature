Feature: ShrugCommand action
  As a developer of the Aethyr engine
  I want ShrugCommand#action to produce the correct emote messages
  So that players can shrug with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Shrug with no target
    When the ShrugCommand action is invoked with no target
    Then the emcmd player should see "You shrug your shoulders."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer shrugs his shoulders."

  Scenario: Shrug targeting self
    When the ShrugCommand action is invoked targeting self
    Then the emcmd player direct output should include "Don't just shrug yourself off like that!"
    And the emcmd room should not have received an event

  Scenario: Shrug targeting another player
    Given an emcmd target named "Bob" exists in the room
    When the ShrugCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You give Bob a brief shrug."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer gives you a brief shrug."
    And the emcmd event to_other should be "TestPlayer gives Bob a brief shrug."
