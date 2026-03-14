Feature: YawnCommand action
  As a developer of the Aethyr engine
  I want YawnCommand#action to produce the correct emote messages
  So that players can yawn with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Yawn with no target
    When the YawnCommand action is invoked with no target
    Then the emcmd player should see "You open your mouth in a wide yawn, then exhale loudly."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer opens his mouth in a wide yawn, then exhales loudly."

  Scenario: Yawn targeting self
    When the YawnCommand action is invoked targeting self
    Then the emcmd player should see "You yawn at how boring you are."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer yawns at himself."
    And the emcmd event to_deaf_other should be "TestPlayer yawns at himself."

  Scenario: Yawn targeting another
    Given an emcmd target named "Bob" exists in the room
    When the YawnCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You yawn at Bob, bored out of your mind."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer yawns at you, finding you boring."
    And the emcmd event to_other should be "TestPlayer yawns at how boring Bob is."
    And the emcmd event to_deaf_other should be "TestPlayer yawns at how boring Bob is."
