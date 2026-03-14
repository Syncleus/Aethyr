Feature: CryCommand action
  As a developer of the Aethyr engine
  I want CryCommand#action to produce the correct emote messages
  So that players can cry with no target.

  Background:
    Given a stubbed emote commands environment

  Scenario: Cry with no target
    When the CryCommand action is invoked with no target
    Then the emcmd player should see "Tears run down your face as you cry pitifully."
    And the emcmd room should have received an event
    And the emcmd event to_other should be "Tears run down TestPlayer's face as he cries pitifully."
