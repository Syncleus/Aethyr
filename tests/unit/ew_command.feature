Feature: EwCommand Emote
  As a player
  I want to use the ew emote
  So that I can express disgust with no target, at myself, or at others

  Background:
    Given a stubbed emote commands environment

  Scenario: Ew with no target
    When the EwCommand action is invoked with no target
    Then the emcmd player should see "\"Ewww!\" you exclaim, looking disgusted."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer exclaims, \"Eww!!\" and looks disgusted."

  Scenario: Ew targeting self
    When the EwCommand action is invoked targeting self
    Then the emcmd player direct output should include "You think you are digusting?"
    And the emcmd room should not have received an event

  Scenario: Ew targeting another player
    Given an emcmd target named "Bob" exists in the room
    When the EwCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You glance at Bob and say \"Ewww!\""
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer glances in your direction and says, \"Ewww!\""
    And the emcmd event to_other should be "TestPlayer glances at Bob, saying \"Ewww!\""
