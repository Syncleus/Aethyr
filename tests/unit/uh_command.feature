Feature: UhCommand action
  As a developer of the Aethyr engine
  I want UhCommand#action to produce the correct emote messages
  So that players can say "Uh..." with no target or at another player.

  Background:
    Given a stubbed emote commands environment

  Scenario: Uh with no target
    When the UhCommand action is invoked with no target
    Then the emcmd player should see "\"Uh...\" you say, staring blankly."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "With a blank stare, TestPlayer says, \"Uh...\""

  Scenario: Uh targeting another
    Given an emcmd target named "Bob" exists in the room
    When the UhCommand action is invoked targeting "Bob"
    Then the emcmd player should see "With a blank stare at Bob, you say, \"Uh...\""
    And the emcmd room should have received an event
    And the emcmd event to_other should be "With a blank stare at Bob, TestPlayer says, \"Uh...\""
    And the emcmd event to_target should be "Staring blankly at you, TestPlayer says, \"Uh...\""
