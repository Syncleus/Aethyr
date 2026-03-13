Feature: NoCommand action
  As a developer of the Aethyr engine
  I want NoCommand#action to produce the correct emote messages
  So that players can say no with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: No with no target
    When the NoCommand action is invoked with no target
    Then the emcmd player should see "\"No,\" you say, shaking your head."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer says, \"No\" and shakes his head."

  Scenario: No targeting self
    When the NoCommand action is invoked targeting self
    Then the emcmd player should see "You shake your head negatively in your direction. You are kind of strange."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer shakes his head at himself."

  Scenario: No targeting another
    Given an emcmd target named "Bob" exists in the room
    When the NoCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You shake your head, disagreeing with Bob."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer shakes his head in your direction, disagreeing."
    And the emcmd event to_other should be "TestPlayer shakes his head in disagreement with Bob."
