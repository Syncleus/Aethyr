Feature: BowCommand action
  As a developer of the Aethyr engine
  I want BowCommand#action to produce the correct emote messages
  So that players can bow with no target, at themselves, or at others.

  Background: 
    Given a stubbed emote commands environment

  Scenario: Bow with no target
    When the BowCommand action is invoked with no target
    Then the emcmd player should see "You bow deeply and respectfully."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer bows deeply and respectfully."

  Scenario: Bow targeting self
    When the BowCommand action is invoked targeting self
    Then the emcmd player direct output should include "Huh?"
    And the emcmd room should not have received an event

  Scenario: Bow targeting another
    Given an emcmd target named "Bob" exists in the room
    When the BowCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You bow respectfully towards Bob."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer bows respectfully before you."
    And the emcmd event to_other should be "TestPlayer bows respectfully towards Bob."
