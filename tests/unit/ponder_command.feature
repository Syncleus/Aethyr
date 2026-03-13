Feature: PonderCommand action
  As a developer of the Aethyr engine
  I want PonderCommand#action to produce the correct emote messages
  So that players can ponder with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Ponder with no target
    When the PonderCommand action is invoked with no target
    Then the emcmd player should see "You ponder that idea for a moment."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer looks thoughtful as he ponders a thought."

  Scenario: Ponder targeting self
    When the PonderCommand action is invoked targeting self
    Then the emcmd player should see "You look down in deep thought at your navel."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer looks down thoughtfully at his navel."

  Scenario: Ponder targeting another
    Given an emcmd target named "Bob" exists in the room
    When the PonderCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You give Bob a thoughtful look as you reflect and ponder."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer gives you a thoughtful look and seems to be reflecting upon something."
    And the emcmd event to_other should be "TestPlayer gives Bob a thoughtful look and appears to be absorbed in reflection."
