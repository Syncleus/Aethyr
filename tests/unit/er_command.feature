Feature: ErCommand action
  As a developer of the Aethyr engine
  I want ErCommand#action to produce the correct emote messages
  So that players can say "er" with no target or directed at another.

  Background:
    Given a stubbed emote commands environment

  Scenario: Er with no target
    When the ErCommand action is invoked with no target
    Then the emcmd player should see "With a look of uncertainty, you say, \"Er...\""
    And the emcmd room should have received an event
    And the emcmd event to_other should be "With a look of uncertainty, TestPlayer says, \"Er...\""

  Scenario: Er targeting another
    Given an emcmd target named "Bob" exists in the room
    When the ErCommand action is invoked targeting "Bob"
    Then the emcmd player should see "Looking at Bob uncertainly, you say, \"Er...\""
    And the emcmd room should have received an event
    And the emcmd event to_other should be "Looking at Bob uncertainly, TestPlayer says, \"Er...\""
    And the emcmd event to_target should be "Looking at you uncertainly, TestPlayer says, \"Er...\""
