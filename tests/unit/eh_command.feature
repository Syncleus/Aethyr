Feature: EhCommand action
  As a developer of the Aethyr engine
  I want EhCommand#action to produce the correct emote messages
  So that players can say eh with no target or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Eh with no target
    When the EhCommand action is invoked with no target
    Then the emcmd player should see "After a brief consideration, you give an unimpressed, 'Eh.'"
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer appears to consider for a moment before giving an unimpressed, 'Eh.'"

  Scenario: Eh targeting another
    Given an emcmd target named "Bob" exists in the room
    When the EhCommand action is invoked targeting "Bob"
    Then the emcmd player should see "After giving Bob a cursory glance, you emit an unimpressed, 'Eh.'"
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer gives Bob a cursory glance and then emits an unimpressed, 'Eh.'"
    And the emcmd event to_target should be "TestPlayer gives you a cursory glance and then emits an unimpressed, 'Eh.'"
