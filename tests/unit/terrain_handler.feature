Feature: TerrainHandler input parsing
  In order to ensure the TerrainHandler correctly routes admin input to TerrainCommand
  As a maintainer of the Aethyr engine
  I want the TerrainHandler player_input method to parse terrain commands.

  Background:
    Given a stubbed TerrainHandler input environment

  # --- "terrain area <value>" branch (lines 38-41) ---
  Scenario: terrain area with a type submits a TerrainCommand targeting area
    When the terrain handler input is "terrain area grassland"
    Then the terrain handler should have submitted 1 action
    And the submitted terrain action should have target "area"
    And the submitted terrain action should have value "grassland"

  Scenario: terrain area with multi-word value submits a TerrainCommand
    When the terrain handler input is "terrain area lush forest"
    Then the terrain handler should have submitted 1 action
    And the submitted terrain action should have target "area"
    And the submitted terrain action should have value "lush forest"

  # --- "terrain room <setting> <value>" branch (lines 42-46) ---
  Scenario: terrain here type submits a TerrainCommand targeting room with type setting
    When the terrain handler input is "terrain here type forest"
    Then the terrain handler should have submitted 1 action
    And the submitted terrain action should have target "room"
    And the submitted terrain action should have setting "type"
    And the submitted terrain action should have value "forest"

  Scenario: terrain room type submits a TerrainCommand targeting room with type setting
    When the terrain handler input is "terrain room type city"
    Then the terrain handler should have submitted 1 action
    And the submitted terrain action should have target "room"
    And the submitted terrain action should have setting "type"
    And the submitted terrain action should have value "city"

  Scenario: terrain here indoors yes submits a TerrainCommand with indoors setting
    When the terrain handler input is "terrain here indoors yes"
    Then the terrain handler should have submitted 1 action
    And the submitted terrain action should have target "room"
    And the submitted terrain action should have setting "indoors"
    And the submitted terrain action should have value "yes"

  Scenario: terrain here water no submits a TerrainCommand with water setting
    When the terrain handler input is "terrain here water no"
    Then the terrain handler should have submitted 1 action
    And the submitted terrain action should have target "room"
    And the submitted terrain action should have setting "water"
    And the submitted terrain action should have value "no"

  Scenario: terrain here underwater yes submits a TerrainCommand with underwater setting
    When the terrain handler input is "terrain here underwater yes"
    Then the terrain handler should have submitted 1 action
    And the submitted terrain action should have target "room"
    And the submitted terrain action should have setting "underwater"
    And the submitted terrain action should have value "yes"

  Scenario: terrain room setting is downcased
    When the terrain handler input is "terrain room type Forest"
    Then the terrain handler should have submitted 1 action
    And the submitted terrain action should have setting "type"
    And the submitted terrain action should have value "Forest"

  Scenario: terrain room with uppercase setting does not match
    When the terrain handler input is "terrain room Type Forest"
    Then the terrain handler should have submitted 0 actions

  # --- Non-matching input does not submit ---
  Scenario: Non-matching input does not submit any action
    When the terrain handler input is "look around"
    Then the terrain handler should have submitted 0 actions
