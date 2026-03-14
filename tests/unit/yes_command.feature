Feature: YesCommand action
  As a developer of the Aethyr engine
  I want YesCommand#action to produce the correct emote messages
  So that players can say yes with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  # Covers lines 9, 15-17, 19-21 (constructor, action setup, no_target block)
  Scenario: Yes with no target
    When the YesCommand action is invoked with no target
    Then the emcmd player should see "\"Yes,\" you say, nodding."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer says, \"Yes\" and nods."

  # Covers lines 9, 15-17, 24-27 (constructor, action setup, self_target block + to_deaf_other)
  Scenario: Yes targeting self
    When the YesCommand action is invoked targeting self
    Then the emcmd player should see "You nod in agreement with yourself."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer nods at himself strangely."
    And the emcmd event to_deaf_other should be "TestPlayer nods at himself strangely."

  # Covers lines 9, 15-17, 30-34 (constructor, action setup, target block + to_deaf_other)
  Scenario: Yes targeting another
    Given an emcmd target named "Bob" exists in the room
    When the YesCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You nod in agreement with Bob."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer nods in your direction, agreeing."
    And the emcmd event to_other should be "TestPlayer nods in agreement with Bob."
    And the emcmd event to_deaf_other should be "TestPlayer nods in agreement with Bob."
