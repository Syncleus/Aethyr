Feature: AdescHandler input parsing
  In order to ensure the AdescHandler correctly routes admin input to AdescCommand
  As a maintainer of the Aethyr engine
  I want the AdescHandler player_input method to parse adesc commands.

  Background:
    Given a stubbed AdescHandler input environment

  # --- "adesc inroom <object> <desc>" branch (lines 38-42) ---
  Scenario: adesc inroom with description submits an AdescCommand
    When the adesc handler input is "adesc inroom fountain A glowing fountain sits here"
    Then the adesc handler should have submitted 1 action
    And the submitted adesc action should have object "fountain"
    And the submitted adesc action should have inroom true
    And the submitted adesc action should have desc "A glowing fountain sits here"

  Scenario: adesc inroom with single-word description
    When the adesc handler input is "adesc inroom chest Sparkling"
    Then the adesc handler should have submitted 1 action
    And the submitted adesc action should have object "chest"
    And the submitted adesc action should have inroom true
    And the submitted adesc action should have desc "Sparkling"

  Scenario: adesc inroom is case-insensitive
    When the adesc handler input is "ADESC INROOM sword A battered blade"
    Then the adesc handler should have submitted 1 action
    And the submitted adesc action should have object "sword"
    And the submitted adesc action should have inroom true
    And the submitted adesc action should have desc "A battered blade"

  # --- "adesc <object> <desc>" branch (lines 43-46) ---
  Scenario: adesc with object and description submits an AdescCommand
    When the adesc handler input is "adesc sword A gleaming blade of light"
    Then the adesc handler should have submitted 1 action
    And the submitted adesc action should have object "sword"
    And the submitted adesc action should have desc "A gleaming blade of light"

  Scenario: adesc with single-word description
    When the adesc handler input is "adesc gem Sparkling"
    Then the adesc handler should have submitted 1 action
    And the submitted adesc action should have object "gem"
    And the submitted adesc action should have desc "Sparkling"

  Scenario: adesc is case-insensitive
    When the adesc handler input is "Adesc Shield A sturdy wooden shield"
    Then the adesc handler should have submitted 1 action
    And the submitted adesc action should have object "Shield"
    And the submitted adesc action should have desc "A sturdy wooden shield"

  # --- Non-matching input does not submit ---
  Scenario: Non-matching input does not submit any action
    When the adesc handler input is "look around"
    Then the adesc handler should have submitted 0 actions

  Scenario: Bare adesc with no arguments does not submit
    When the adesc handler input is "adesc"
    Then the adesc handler should have submitted 0 actions
