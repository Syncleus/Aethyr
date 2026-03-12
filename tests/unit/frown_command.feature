Feature: FrownCommand action
  As a developer of the Aethyr engine
  I want FrownCommand#action to produce the correct emote messages
  So that players can frown with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Frown with no target
    When the FrownCommand action is invoked with no target
    Then the emcmd player should see "The edges of your mouth turn down as you frown."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "The edges of TestPlayer's mouth turn down as he frowns."

  Scenario: Frown targeting self
    When the FrownCommand action is invoked targeting self
    Then the emcmd player should see "You frown sadly at yourself."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer frowns sadly at himself."

  Scenario: Frown targeting another
    Given an emcmd target named "Bob" exists in the room
    When the FrownCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You frown at Bob unhappily."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer frowns at you unhappily."
