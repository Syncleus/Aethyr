Feature: FillCommand action
  In order to let players fill liquid containers from other liquid containers
  As a maintainer of the Aethyr engine
  I want FillCommand#action to correctly handle all fill scenarios.

  Background:
    Given a stubbed FillCommand environment

  # --- initialize (line 9) + object nil (lines 14-16, 18-20) -----------------
  Scenario: Object not found produces a prompt
    Given the fill object name is "bucket"
    And the fill from name is "well"
    And the fill object is not found
    When the FillCommand action is invoked
    Then the fill player should see "What would you like to fill?"

  # --- object is not a LiquidContainer (lines 21-23) -------------------------
  Scenario: Object is not a liquid container
    Given the fill object name is "rock"
    And the fill from name is "well"
    And the fill object is a non-liquid item named "a rock"
    When the FillCommand action is invoked
    Then the fill player should see "You cannot fill a rock with liquids."

  # --- from is nil (lines 24-26) ---------------------------------------------
  Scenario: Source not found
    Given the fill object name is "bucket"
    And the fill from name is "pond"
    And the fill object is a liquid container named "bucket"
    And the fill from is not found
    When the FillCommand action is invoked
    Then the fill player should see "There isn't any pond around here."

  # --- from is not a LiquidContainer (lines 27-29) ---------------------------
  Scenario: Source is not a liquid container
    Given the fill object name is "bucket"
    And the fill from name is "table"
    And the fill object is a liquid container named "bucket"
    And the fill from is a non-liquid item named "a table"
    When the FillCommand action is invoked
    Then the fill player should see "You cannot fill bucket from a table."

  # --- from is empty (lines 30-32) -------------------------------------------
  Scenario: Source is empty
    Given the fill object name is "bucket"
    And the fill from name is "barrel"
    And the fill object is a liquid container named "bucket" with generic "bucket"
    And the fill from is an empty liquid container named "barrel" with generic "barrel"
    When the FillCommand action is invoked
    Then the fill player should see "That bucket is empty."

  # --- object is full (lines 33-35) ------------------------------------------
  Scenario: Object is already full
    Given the fill object name is "bucket"
    And the fill from name is "barrel"
    And the fill object is a full liquid container named "bucket" with generic "bucket"
    And the fill from is a non-empty liquid container named "barrel" with generic "barrel"
    When the FillCommand action is invoked
    Then the fill player should see "That bucket is full."

  # --- object == from (lines 36-38) ------------------------------------------
  Scenario: Filling from itself
    Given the fill object name is "bucket"
    And the fill from name is "bucket"
    And the fill object and from are the same liquid container named "bucket"
    When the FillCommand action is invoked
    Then the fill player should see "Quickly flipping bucket upside-down then upright again, you manage to fill it from itself."
