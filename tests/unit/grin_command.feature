Feature: GrinCommand action
  As a developer of the Aethyr engine
  I want GrinCommand#action to produce the correct emote messages
  So that players can grin with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Grin with no target
    When the GrinCommand action is invoked with no target
    Then the emcmd player should see "You grin widely, flashing all your teeth."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer grins widely, flashing all his teeth."

  Scenario: Grin targeting self
    When the GrinCommand action is invoked targeting self
    Then the emcmd player should see "You grin madly at yourself."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer grins madly at himself."

  Scenario: Grin targeting another
    Given an emcmd target named "Bob" exists in the room
    When the GrinCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You give Bob a wide grin."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer gives you a wide grin."
