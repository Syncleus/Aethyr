Feature: HmCommand action
  As a developer of the Aethyr engine
  I want HmCommand#action to produce the correct emote messages
  So that players can hm with no target, at themselves, or at others.

  Background:
    Given a stubbed emote commands environment

  Scenario: Hm with no target
    When the HmCommand action is invoked with no target
    Then the emcmd player should see "You purse your lips thoughtfully and say, \"Hmmm...\""
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer purses his lips thoughtfully and says, \"Hmmm...\""

  Scenario: Hm targeting self
    When the HmCommand action is invoked targeting self
    Then the emcmd player should see "You look down at yourself and say, \"Hmmm...\""
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer looks down at himself and says, \"Hmmm...\""

  Scenario: Hm targeting another
    Given an emcmd target named "Bob" exists in the room
    When the HmCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You purse your lips as you look thoughtfully at Bob and say, \"Hmmm...\""
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer purses his lips as he looks thoughtfully at you and says, \"Hmmm...\""
    And the emcmd event to_other should be "TestPlayer purses his lips as he looks thoughtfully at Bob and says, \"Hmmm...\""
