Feature: Syntax reference lookup
  The Syntax module provides a quick-reference dictionary so the
  engine can display correct usage when a player mistypes a command.

  Scenario: Finding syntax for a known command
    Given I require the Syntax library
    When I look up the syntax for "say"
    Then the syntax result should be "You open your mouth but find no words to say."

  Scenario: Finding syntax for an unknown command returns nil
    Given I require the Syntax library
    When I look up the syntax for "nonexistent_command"
    Then the syntax result should be nil
