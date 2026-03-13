Feature: CheerCommand action
  As a developer of the Aethyr engine
  I want CheerCommand#action to produce the correct emote messages
  So that players can cheer with no target, at themselves, or at others.

  Background: 
    Given a stubbed emote commands environment

  Scenario: Cheer with no target
    When the CheerCommand action is invoked with no target
    Then the emcmd player should see "You throw your hands in the air and cheer wildly!"
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer throws his hands in the air as he cheers wildy!"

  Scenario: Cheer targeting self
    When the CheerCommand action is invoked targeting self
    Then the emcmd player direct output should include "Hm? How do you do that?"
    And the emcmd room should not have received an event

  Scenario: Cheer targeting another
    Given an emcmd target named "Bob" exists in the room
    When the CheerCommand action is invoked targeting "Bob"
    Then the emcmd player should see "Beaming at Bob, you throw your hands up and cheer for him."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "Beaming at you, TestPlayer throws his hands up and cheers for you."
    And the emcmd event to_other should be "TestPlayer throws his hands up and cheers for Bob."
