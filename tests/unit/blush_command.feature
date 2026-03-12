Feature: BlushCommand action
  As a developer of the Aethyr engine
  I want BlushCommand#action to produce the correct emote messages
  So that players can blush with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Blush with no target
    When the BlushCommand action is invoked with no target
    Then the emcmd player should see "You feel the blood rush to your cheeks and you look down, blushing."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer's face turns bright red as he looks down, blushing."

  Scenario: Blush targeting self
    When the BlushCommand action is invoked targeting self
    Then the emcmd player should see "You blush at your foolishness."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer blushes at his foolishness."

  Scenario: Blush targeting another
    Given an emcmd target named "Bob" exists in the room
    When the BlushCommand action is invoked targeting "Bob"
    Then the emcmd player should see "Your face turns red and you blush at Bob uncomfortably."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer blushes in your direction."
