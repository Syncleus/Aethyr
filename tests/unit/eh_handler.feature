Feature: Eh emote input handler
  In order to express indifference through natural commands
  As a player
  I want the EhHandler to translate my textual input into the correct EhCommand objects.

  Background:
    Given a stubbed EhHandler environment

  Scenario: Eh with no target and no post
    When the eh player enters "eh"
    Then the eh manager should receive an EhCommand
    And the EhCommand object should be nil
    And the EhCommand post should be nil

  Scenario: Eh with a target
    When the eh player enters "eh Bob"
    Then the eh manager should receive an EhCommand
    And the EhCommand object should be "Bob"
    And the EhCommand post should be nil

  Scenario: Eh with a target and post
    When the eh player enters "eh Bob (shrugging)"
    Then the eh manager should receive an EhCommand
    And the EhCommand object should be "Bob"
    And the EhCommand post should be "(shrugging)"

  Scenario: Non-matching input does not produce an EhCommand
    When the eh player enters "laugh"
    Then the eh manager should not receive any action
