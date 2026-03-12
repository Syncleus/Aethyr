Feature: TerrainCommand action
  In order to let admins modify terrain attributes on rooms and areas
  As a maintainer of the Aethyr engine
  I want TerrainCommand#action to correctly dispatch terrain changes.

  Background:
    Given a stubbed TerrainCommand environment

  # --- target "area" with no area (lines 17-20) ------------------------------
  Scenario: Setting terrain on area when room has no area
    Given the terrain target is "area"
    And the terrain value is "grassland"
    When the TerrainCommand action is invoked
    Then the terrain player should see "This room is not in an area."

  # --- target "area" with valid area (lines 17, 23, 25, 27) ------------------
  Scenario: Setting terrain type on area
    Given the room has an area
    And the terrain target is "area"
    And the terrain value is "Grassland"
    When the TerrainCommand action is invoked
    Then the terrain player should see "Set TestArea terrain type to grassland"

  # --- setting "type" (lines 30, 32-33) --------------------------------------
  Scenario: Setting room terrain type
    Given the terrain setting is "type"
    And the terrain value is "Forest"
    When the TerrainCommand action is invoked
    Then the terrain player should see "Set Test Room terrain type to forest"

  # --- setting "indoors" yes (lines 30, 35-37) --------------------------------
  Scenario: Setting indoors to yes
    Given the terrain setting is "indoors"
    And the terrain value is "yes"
    When the TerrainCommand action is invoked
    Then the terrain player should see "Room is now indoors."

  # --- setting "indoors" no (lines 30, 38-40) ---------------------------------
  Scenario: Setting indoors to no
    Given the terrain setting is "indoors"
    And the terrain value is "no"
    When the TerrainCommand action is invoked
    Then the terrain player should see "Room is now outdoors."

  # --- setting "indoors" invalid (lines 30, 42) -------------------------------
  Scenario: Setting indoors to invalid value
    Given the terrain setting is "indoors"
    And the terrain value is "maybe"
    When the TerrainCommand action is invoked
    Then the terrain player should see "Indoors: yes or no?"

  # --- setting "water" yes (lines 30, 45-47) ----------------------------------
  Scenario: Setting water to yes
    Given the terrain setting is "water"
    And the terrain value is "true"
    When the TerrainCommand action is invoked
    Then the terrain player should see "Room is now water."

  # --- setting "water" no (lines 30, 48-50) -----------------------------------
  Scenario: Setting water to no
    Given the terrain setting is "water"
    And the terrain value is "false"
    When the TerrainCommand action is invoked
    Then the terrain player should see "Room is now dry."

  # --- setting "water" invalid (lines 30, 52) ---------------------------------
  Scenario: Setting water to invalid value
    Given the terrain setting is "water"
    And the terrain value is "maybe"
    When the TerrainCommand action is invoked
    Then the terrain player should see "Water: yes or no?"

  # --- setting "underwater" yes (lines 30, 55-57) -----------------------------
  Scenario: Setting underwater to yes
    Given the terrain setting is "underwater"
    And the terrain value is "yes"
    When the TerrainCommand action is invoked
    Then the terrain player should see "Room is now underwater."

  # --- setting "underwater" no (lines 30, 58-60) ------------------------------
  Scenario: Setting underwater to no
    Given the terrain setting is "underwater"
    And the terrain value is "false"
    When the TerrainCommand action is invoked
    Then the terrain player should see "Room is now above water."

  # --- setting "underwater" invalid (lines 30, 62) ----------------------------
  Scenario: Setting underwater to invalid value
    Given the terrain setting is "underwater"
    And the terrain value is "maybe"
    When the TerrainCommand action is invoked
    Then the terrain player should see "Underwater: yes or no?"

  # --- unknown setting (line 65) ----------------------------------------------
  Scenario: Unknown setting produces an error
    Given the terrain setting is "bogus"
    And the terrain value is "whatever"
    When the TerrainCommand action is invoked
    Then the terrain player should see "What are you trying to set?"
