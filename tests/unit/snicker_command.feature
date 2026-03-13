Feature: SnickerCommand action
  As a developer of the Aethyr engine
  I want SnickerCommand#action to produce the correct emote messages
  So that players can snicker with no target, at themselves, or at others.

  Background: 
    Given a stubbed emote commands environment

  Scenario: Snicker with no target
    When the SnickerCommand action is invoked with no target
    Then the emcmd player should see "You snicker softly to yourself."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "You hear TestPlayer snicker softly."

  Scenario: Snicker targeting self
    When the SnickerCommand action is invoked targeting self
    Then the emcmd player direct output should include "What are you snickering about?"
    And the emcmd room should not have received an event

  Scenario: Snicker targeting another
    Given an emcmd target named "Bob" exists in the room
    When the SnickerCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You snicker at Bob under your breath."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer snickers at you under his breath."
    And the emcmd event to_other should be "TestPlayer snickers at Bob under his breath."
