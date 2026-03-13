Feature: HugCommand Emote
  As a player
  I want to use the hug emote
  So that I can hug myself or others affectionately

  Background:
    Given a stubbed emote commands environment

  Scenario: Hug with no target
    When the HugCommand action is invoked with no target
    Then the emcmd player direct output should include "Who are you trying to hug?"
    Then the emcmd room should not have received an event

  Scenario: Hug targeting self
    When the HugCommand action is invoked targeting self
    Then the emcmd player should see "You wrap your arms around yourself and give a tight squeeze."
    Then the emcmd room should have received an event
    Then the emcmd event to_other should be "TestPlayer gives himself a tight squeeze."

  Scenario: Hug targeting another player
    Given an emcmd target named "Bob" exists in the room
    When the HugCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You give Bob a great big hug."
    Then the emcmd room should have received an event
    Then the emcmd event to_target should be "TestPlayer gives you a great big hug."
    Then the emcmd event to_other should be "TestPlayer gives Bob a great big hug."
