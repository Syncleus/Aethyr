Feature: Areact command input handler
  In order to manage reactions on game objects via textual commands
  As an admin player
  I want the Areact input handler to translate my textual input into the correct AreactionCommand objects.

  Background:
    Given a stubbed AreactHandler environment

  # --- "areact load <object> <file>" branch (lines 38-42) ---
  Scenario: Parse areact load command
    When the admin enters "areact load sword sparkle"
    Then the manager should receive an AreactionCommand
    And the submitted areaction command should be "load"
    And the submitted areaction object should be "sword"
    And the submitted areaction file should be "sparkle"

  Scenario: Parse areact load command with multi-word object
    When the admin enters "areact load big sword sparkle"
    Then the manager should receive an AreactionCommand
    And the submitted areaction command should be "load"
    And the submitted areaction object should be "big sword"
    And the submitted areaction file should be "sparkle"

  Scenario: Parse areact load command case-insensitive
    When the admin enters "AREACT LOAD shield firefile"
    Then the manager should receive an AreactionCommand
    And the submitted areaction command should be "load"
    And the submitted areaction object should be "shield"
    And the submitted areaction file should be "firefile"

  # --- "areact reload|clear|show <object>" branch (lines 43-46) ---
  Scenario: Parse areact reload command
    When the admin enters "areact reload sword"
    Then the manager should receive an AreactionCommand
    And the submitted areaction command should be "reload"
    And the submitted areaction object should be "sword"

  Scenario: Parse areact clear command
    When the admin enters "areact clear sword"
    Then the manager should receive an AreactionCommand
    And the submitted areaction command should be "clear"
    And the submitted areaction object should be "sword"

  Scenario: Parse areact show command
    When the admin enters "areact show sword"
    Then the manager should receive an AreactionCommand
    And the submitted areaction command should be "show"
    And the submitted areaction object should be "sword"

  Scenario: Parse areact show with multi-word object
    When the admin enters "areact show big chest"
    Then the manager should receive an AreactionCommand
    And the submitted areaction command should be "show"
    And the submitted areaction object should be "big chest"

  Scenario: Parse areact reload case-insensitive
    When the admin enters "AREACT RELOAD shield"
    Then the manager should receive an AreactionCommand
    And the submitted areaction command should be "RELOAD"
    And the submitted areaction object should be "shield"

  # --- "areact add|delete <object> <action_name>" branch (lines 47-51) ---
  Scenario: Parse areact add command
    When the admin enters "areact add sword wave"
    Then the manager should receive an AreactionCommand
    And the submitted areaction command should be "add"
    And the submitted areaction object should be "sword"
    And the submitted areaction action_name should be "wave"

  Scenario: Parse areact delete command
    When the admin enters "areact delete sword wave"
    Then the manager should receive an AreactionCommand
    And the submitted areaction command should be "delete"
    And the submitted areaction object should be "sword"
    And the submitted areaction action_name should be "wave"

  Scenario: Parse areact add with multi-word object
    When the admin enters "areact add big sword nod"
    Then the manager should receive an AreactionCommand
    And the submitted areaction command should be "add"
    And the submitted areaction object should be "big sword"
    And the submitted areaction action_name should be "nod"

  Scenario: Parse areact delete case-insensitive
    When the admin enters "AREACT DELETE shield kick"
    Then the manager should receive an AreactionCommand
    And the submitted areaction command should be "DELETE"
    And the submitted areaction object should be "shield"
    And the submitted areaction action_name should be "kick"

  # --- Non-matching input produces no action ---
  Scenario: Non-matching input does not produce an action
    When the admin enters "areact"
    Then the manager should not receive any action
