Feature: AinfoHandler input parsing
  In order to ensure the AinfoHandler correctly routes admin input to AinfoCommand
  As a maintainer of the Aethyr engine
  I want the AinfoHandler player_input method to parse ainfo commands.

  Background:
    Given a stubbed AinfoHandler input environment

  # --- "ainfo set <object> @<attrib> <value>" branch (lines 39-43) ---
  Scenario: ainfo set with simple value submits an AinfoCommand
    When the ainfo handler input is "ainfo set sword @name Excalibur"
    Then the ainfo handler should have submitted 1 action
    And the submitted ainfo action should have command "set"
    And the submitted ainfo action should have object "sword"
    And the submitted ainfo action should have attrib "name"
    And the submitted ainfo action should have value "Excalibur"

  Scenario: ainfo set with dotted attribute submits an AinfoCommand
    When the ainfo handler input is "ainfo set gem @stats.power 99"
    Then the ainfo handler should have submitted 1 action
    And the submitted ainfo action should have command "set"
    And the submitted ainfo action should have object "gem"
    And the submitted ainfo action should have attrib "stats.power"
    And the submitted ainfo action should have value "99"

  Scenario: ainfo set with underscore attribute submits an AinfoCommand
    When the ainfo handler input is "ainfo set chest @is_locked true"
    Then the ainfo handler should have submitted 1 action
    And the submitted ainfo action should have command "set"
    And the submitted ainfo action should have object "chest"
    And the submitted ainfo action should have attrib "is_locked"
    And the submitted ainfo action should have value "true"

  Scenario: ainfo set with multi-word value submits an AinfoCommand
    When the ainfo handler input is "ainfo set sword @desc a shiny blade of light"
    Then the ainfo handler should have submitted 1 action
    And the submitted ainfo action should have command "set"
    And the submitted ainfo action should have object "sword"
    And the submitted ainfo action should have attrib "desc"
    And the submitted ainfo action should have value "a shiny blade of light"

  # --- "ainfo show <object>" branch (lines 45-47) ---
  Scenario: ainfo show submits an AinfoCommand
    When the ainfo handler input is "ainfo show sword"
    Then the ainfo handler should have submitted 1 action
    And the submitted ainfo action should have command "show"
    And the submitted ainfo action should have object "sword"

  Scenario: ainfo show with multi-word object reference
    When the ainfo handler input is "ainfo show rusty old sword"
    Then the ainfo handler should have submitted 1 action
    And the submitted ainfo action should have command "show"
    And the submitted ainfo action should have object "rusty old sword"

  # --- "ainfo clear <object>" branch (lines 45-47) ---
  Scenario: ainfo clear submits an AinfoCommand
    When the ainfo handler input is "ainfo clear gem"
    Then the ainfo handler should have submitted 1 action
    And the submitted ainfo action should have command "clear"
    And the submitted ainfo action should have object "gem"

  # --- "ainfo delete <object> @<attrib>" branch (lines 49-52) ---
  Scenario: ainfo delete submits an AinfoCommand
    When the ainfo handler input is "ainfo delete sword @name"
    Then the ainfo handler should have submitted 1 action
    And the submitted ainfo action should have command "delete"
    And the submitted ainfo action should have object "sword"
    And the submitted ainfo action should have attrib "name"

  Scenario: ainfo del alias submits an AinfoCommand
    When the ainfo handler input is "ainfo del chest @is_locked"
    Then the ainfo handler should have submitted 1 action
    And the submitted ainfo action should have command "delete"
    And the submitted ainfo action should have object "chest"
    And the submitted ainfo action should have attrib "is_locked"

  Scenario: ainfo delete with dotted attribute submits an AinfoCommand
    When the ainfo handler input is "ainfo delete gem @stats.power"
    Then the ainfo handler should have submitted 1 action
    And the submitted ainfo action should have command "delete"
    And the submitted ainfo action should have object "gem"
    And the submitted ainfo action should have attrib "stats.power"

  # --- Non-matching input does not submit ---
  Scenario: Non-matching input does not submit any action
    When the ainfo handler input is "look around"
    Then the ainfo handler should have submitted 0 actions
