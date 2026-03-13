Feature: NodCommand action
  As a developer of the Aethyr engine
  I want NodCommand#action to produce the correct emote messages
  So that players can nod with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Nod with no target
    When the NodCommand action is invoked with no target
    Then the emcmd player should see "You nod your head."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer nods his head."

  Scenario: Nod targeting self
    When the NodCommand action is invoked targeting self
    Then the emcmd player should see "You nod to yourself thoughtfully."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer nods to himself thoughtfully."

  Scenario: Nod targeting another
    Given an emcmd target named "Bob" exists in the room
    When the NodCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You nod your head towards Bob."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer nods his head towards you."
    And the emcmd event to_other should be "TestPlayer nods his head towards Bob."
