Feature: PokeCommand Emote
  As a player
  I want to use the poke emote
  So that I can poke myself or others playfully

  Background:
    Given a stubbed emote commands environment

  Scenario: Poke with no target
    When the PokeCommand action is invoked with no target
    Then the emcmd player direct output should include "Who are you trying to poke?"
    Then the emcmd room should not have received an event

  Scenario: Poke targeting self
    When the PokeCommand action is invoked targeting self
    Then the emcmd player should see "You poke yourself in the eye. 'Ow!'"
    Then the emcmd room should have received an event
    Then the emcmd event to_other should be "TestPlayer pokes himself in the eye."

  Scenario: Poke targeting another player
    Given an emcmd target named "Bob" exists in the room
    When the PokeCommand action is invoked targeting "Bob"
    Then the emcmd player should see "You poke Bob playfully."
    Then the emcmd room should have received an event
    Then the emcmd event to_target should be "TestPlayer pokes you playfully."
    Then the emcmd event to_other should be "TestPlayer pokes Bob playfully."
