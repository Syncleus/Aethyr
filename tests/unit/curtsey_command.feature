Feature: CurtseyCommand action
  As a developer of the Aethyr engine
  I want CurtseyCommand#action to produce the correct emote messages
  So that players can curtsey with no target, at themselves, or at others.

  Background: 
    Given a stubbed emote commands environment

  Scenario: Curtsey with no target
    When the CurtseyCommand action is invoked with no target
    Then the emcmd player should see "You perform a very graceful curtsey."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "TestPlayer curtseys quite gracefully."

  Scenario: Curtsey targeting self
    When the CurtseyCommand action is invoked targeting self
    Then the emcmd player direct output should include "Hm? How do you do that?"
    And the emcmd room should not have received an event

  Scenario: Curtsey targeting another
    Given an emcmd target named "Bob" exists in the room
    When the CurtseyCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You curtsey gracefully and respectfully towards Bob."
    And the emcmd room should have received an event
    And the emcmd event to_target should be "TestPlayer curtseys gracefully and respectfully in your direction."
    And the emcmd event to_other should be "TestPlayer curtseys gracefully and respectfully towards Bob."
