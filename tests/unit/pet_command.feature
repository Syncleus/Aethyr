Feature: PetCommand Emote
  As a player
  I want to use the pet emote
  So that I can pet myself or others affectionately

  Background:
    Given a stubbed emote commands environment

  Scenario: Pet with no target
    When the PetCommand action is invoked with no target
    Then the emcmd player direct output should include "Who are you trying to pet?"
    Then the emcmd room should not have received an event

  Scenario: Pet targeting self
    When the PetCommand action is invoked targeting self
    Then the emcmd player should see "You pet yourself on the head in a calming manner."
    Then the emcmd room should have received an event
    Then the emcmd event to_other should be "TestPlayer pets himself on the head in a calming manner."

  Scenario: Pet targeting another player
    Given an emcmd target named "Bob" exists in the room
    When the PetCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You pet Bob affectionately."
    Then the emcmd room should have received an event
    Then the emcmd event to_target should be "TestPlayer pets you affectionately."
    Then the emcmd event to_other should be "TestPlayer pets Bob affectionately."
