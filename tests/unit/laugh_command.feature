Feature: LaughCommand action
  As a developer of the Aethyr engine
  I want LaughCommand#action to produce the correct emote messages
  So that players can laugh with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Laugh with no target
    When the LaughCommand action is invoked with no target
    Then the emcmd player should see "You laugh."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer laughs."

  Scenario: Laugh targeting self
    When the LaughCommand action is invoked targeting self
    Then the emcmd player should see "You laugh heartily at yourself."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer laughs heartily at himself."

  Scenario: Laugh targeting another
    Given an emcmd target named "Bob" exists in the room
    When the LaughCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You laugh at Bob."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer laughs at you."
