Feature: AgreeCommand action
  As a developer of the Aethyr engine
  I want AgreeCommand#action to produce the correct emote messages
  So that players can agree with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Agree with no target
    When the AgreeCommand action is invoked with no target
    Then the emcmd player should see "You nod your head in agreement."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer nods his head in agreement."

  Scenario: Agree targeting self
    When the AgreeCommand action is invoked targeting self
    Then the emcmd player should see "You are in complete agreement with yourself."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer nods at himself, apparently in complete agreement."

  Scenario: Agree targeting another
    Given an emcmd target named "Bob" exists in the room
    When the AgreeCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You nod your head in agreement with Bob."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer nods his head in agreement with you."
