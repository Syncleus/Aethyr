Feature: HiCommand action
  As a developer of the Aethyr engine
  I want HiCommand#action to produce the correct emote messages
  So that players can hi with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Hi with no target
    When the HiCommand action is invoked with no target
    Then the emcmd player should see "\"Hi!\" you greet those around you."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer greets those around with a \"Hi!\""

  Scenario: Hi targeting self
    When the HiCommand action is invoked targeting self
    Then the emcmd player direct output should include "Hi."
    And the emcmd room should not have received an event

  Scenario: Hi targeting another
    Given an emcmd target named "Bob" exists in the room
    When the HiCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You say \"Hi!\" in greeting to Bob."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer greets you with a \"Hi!\""
    And the emcmd event to_other should be "TestPlayer greets Bob with a hearty \"Hi!\""
