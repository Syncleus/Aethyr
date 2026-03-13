Feature: SmileCommand action
  As a developer of the Aethyr engine
  I want SmileCommand#action to produce the correct emote messages
  So that players can smile with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Smile with no target
    When the SmileCommand action is invoked with no target
    Then the emcmd player should see "You smile happily."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer smiles happily."

  Scenario: Smile targeting self
    When the SmileCommand action is invoked targeting self
    Then the emcmd player should see "You smile happily at yourself."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer smiles at himself sillily."

  Scenario: Smile targeting another
    Given an emcmd target named "Bob" exists in the room
    When the SmileCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You smile at Bob kindly."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer smiles at you kindly."
    And the emcmd event to_other should be "TestPlayer smiles at Bob kindly."
