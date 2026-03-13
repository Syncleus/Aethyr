Feature: YesCommand action
  As a developer of the Aethyr engine
  I want YesCommand#action to produce the correct emote messages
  So that players can say yes with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Yes with no target
    When the YesCommand action is invoked with no target
    Then the emcmd player should see "\"Yes,\" you say, nodding."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer says, \"Yes\" and nods."

  Scenario: Yes targeting self
    When the YesCommand action is invoked targeting self
    Then the emcmd player should see "You nod in agreement with yourself."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer nods at himself strangely."

  Scenario: Yes targeting another
    Given an emcmd target named "Bob" exists in the room
    When the YesCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You nod in agreement with Bob."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer nods in your direction, agreeing."
    And the emcmd event to_other should be "TestPlayer nods in agreement with Bob."
