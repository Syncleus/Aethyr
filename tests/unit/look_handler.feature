Feature: Look command input handler
  In order to interact with the world using natural commands
  As a player
  I want the Look input handler to translate my textual input into the correct LookCommand objects.

  Background:
    # Establish a lightweight test harness with a stubbed manager and player
    Given a stubbed LookHandler environment

  Scenario Outline: Translating input strings into the appropriate LookCommand
    When the player enters "<input>"
    Then the manager should receive a Look command with parameter kind "<kind>" and value "<value>"

    Examples:
      | input             | kind | value |
      | look              | none |       |
      | l                 | none |       |
      | look sword        | at   | sword |
      | l sword           | at   | sword |
      | look in chest     | in   | chest |
      | look inside chest | in   | chest |
      | l in chest        | in   | chest |

  Scenario: Subscribing a newly added player to the LookHandler
    Given a fresh stubbed Player instance
    When the LookHandler receives an object_added notification for that player
    Then the player should have subscribed to a LookHandler instance

  Scenario: Generating contextual help entries for the LOOK command
    When I request the LookHandler help entries
    Then the result should contain exactly one entry
    And the entry should advertise alias "l"
    And the entry should list the syntax token "LOOK" 