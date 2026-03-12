Feature: Position trait
  In order to track a character's posture (sitting, standing, lying)
  As a maintainer of the Aethyr engine
  I want the Position module to manage positions correctly.

  Background:
    Given a fresh positionable object

  # --- sit without target (lines 15-20, 25) -----------------------------------
  Scenario: Sit on the ground when not already sitting
    When the position object sits without a target
    Then the position sit result should be true
    And the position pose should be "sitting on the ground"
    And the position object should be sitting
    And the position sitting_on should be "ground"

  # --- sit with target (lines 15-16, 17 else, 22-23, 25) ----------------------
  Scenario: Sit on a target object
    When the position object sits on a target named "chair" with goid "chair_1"
    Then the position sit result should be true
    And the position pose should be "sitting on chair"
    And the position sitting_on should be "chair_1"

  # --- sit when already sitting (line 27) --------------------------------------
  Scenario: Cannot sit when already sitting
    Given the position object is already sitting
    When the position object sits without a target
    Then the position sit result should be false

  # --- stand when prone, no target (lines 33-37) ------------------------------
  Scenario: Stand up from sitting
    Given the position object is already sitting
    When the position object stands without a target
    Then the position stand result should be true
    And the position pose should be nil
    And the position object should not be sitting
    And the position object should be able to move

  # --- stand when prone from lying, no target (lines 33-37) -------------------
  Scenario: Stand up from lying
    Given the position object is already lying
    When the position object stands without a target
    Then the position stand result should be true
    And the position object should not be lying

  # --- stand with target (lines 38-43) ----------------------------------------
  Scenario: Stand on a target object
    When the position object stands on a target named "table" with goid "table_1"
    Then the position stand result should be true
    And the position pose should be "standing on table"

  # --- stand when not prone, no target (line 45) ------------------------------
  Scenario: Cannot stand when already standing and no target
    When the position object stands without a target
    Then the position stand result should be false

  # --- lie without target (lines 51-53, 55-57, 62) ----------------------------
  Scenario: Lie on the ground
    When the position object lies without a target
    Then the position lie result should be true
    And the position pose should be "lying on the ground"
    And the position object should be lying
    And the position lying_on should be "ground"

  # --- lie with target (lines 51-53, 59-60, 62) -------------------------------
  Scenario: Lie on a target object
    When the position object lies on a target named "bed" with goid "bed_1"
    Then the position lie result should be true
    And the position pose should be "lying on bed"
    And the position lying_on should be "bed_1"

  # --- lie when already lying (line 64) ----------------------------------------
  Scenario: Cannot lie when already lying
    Given the position object is already lying
    When the position object lies without a target
    Then the position lie result should be false

  # --- lie clears sitting position (lines 51-53) ------------------------------
  Scenario: Lying down clears sitting position
    Given the position object is already sitting
    When the position object lies without a target
    Then the position lie result should be true
    And the position object should not be sitting
    And the position object should be lying

  # --- on? with no argument when prone (lines 74-75) --------------------------
  Scenario: on? returns true when prone with no argument
    Given the position object is already sitting
    Then the position object should be on something

  # --- on? with no argument when not prone (lines 74-75) ----------------------
  Scenario: on? returns false when not prone with no argument
    Then the position object should not be on something

  # --- on? with a goid target matching (line 77) ------------------------------
  Scenario: on? returns true for matching goid
    When the position object sits on a target named "chair" with goid "chair_1"
    Then the position object should be on goid "chair_1"

  # --- on? with a goid target not matching (line 77) --------------------------
  Scenario: on? returns false for non-matching goid
    When the position object sits on a target named "chair" with goid "chair_1"
    Then the position object should not be on goid "other_1"

  # --- on? with a GameObject target (lines 70-71) -----------------------------
  Scenario: on? accepts a GameObject and extracts goid
    When the position object sits on a target named "chair" with goid "chair_1"
    Then the position object should be on a game object with goid "chair_1"

  # --- on? with standing_on (line 77) -----------------------------------------
  Scenario: on? detects standing_on
    When the position object stands on a target named "table" with goid "table_1"
    Then the position object should be on goid "table_1"

  # --- on? with lying_on (line 77) --------------------------------------------
  Scenario: on? detects lying_on
    When the position object lies on a target named "bed" with goid "bed_1"
    Then the position object should be on goid "bed_1"

  # --- sitting? (line 83) -----------------------------------------------------
  Scenario: sitting? returns false when not sitting
    Then the position object should not be sitting

  # --- lying? (line 88) -------------------------------------------------------
  Scenario: lying? returns false when not lying
    Then the position object should not be lying

  # --- prone? (line 93) -------------------------------------------------------
  Scenario: prone? returns true when sitting
    Given the position object is already sitting
    Then the position object should be prone

  Scenario: prone? returns true when lying
    Given the position object is already lying
    Then the position object should be prone

  Scenario: prone? returns false when standing
    Then the position object should not be prone

  # --- can_move? (line 98) ----------------------------------------------------
  Scenario: can_move? when standing
    Then the position object should be able to move

  Scenario: can_move? when sitting
    Given the position object is already sitting
    Then the position object should not be able to move

  # --- sitting_on accessor (line 102) -----------------------------------------
  Scenario: sitting_on returns nil when not sitting
    Then the position sitting_on should be nil

  # --- lying_on accessor (line 106) -------------------------------------------
  Scenario: lying_on returns nil when not lying
    Then the position lying_on should be nil

  # --- pose getter (line 110) -------------------------------------------------
  Scenario: pose is nil initially
    Then the position pose should be nil

  # --- pose setter (line 114) -------------------------------------------------
  Scenario: pose can be set directly
    When the position pose is set to "custom pose"
    Then the position pose should be "custom pose"
