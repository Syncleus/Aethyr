Feature: WriteCommand action
  In order to let players write on writable objects in their inventory
  As a developer of the Aethyr engine
  I want the WriteCommand to correctly handle all writing branches.

  Background:
    Given a stubbed WriteCommand environment

  # ── Branch 1: object not found in inventory (lines 14, 16-18) ──────────────

  Scenario: Target object not found in inventory
    Given the write target is not in the player inventory
    When the write command is invoked
    Then the write player should see "What do you wish to write on?"

  # ── Branch 2: object found but not writable (lines 14, 21-23) ──────────────

  Scenario: Target object is not writable
    Given the write target is a non-writable object named "stone tablet"
    When the write command is invoked
    Then the write player should see "You cannot write on stone tablet."

  # ── Branch 3: object writable, editor provides data (lines 14, 26, 28-30, 32)

  Scenario: Writing on a writable object with editor data
    Given the write target is a writable object named "scroll" with existing text
    And the write editor will provide new text
    When the write command is invoked
    Then the write player should see "You begin to write on scroll."
    And the write player should see "You finish your writing."
    And the write object readable text should be updated

  # ── Branch 4: object writable, editor cancelled (data nil) (lines 14, 26, 28, 32)

  Scenario: Writing on a writable object but editor cancelled
    Given the write target is a writable object named "journal" without existing text
    And the write editor will cancel
    When the write command is invoked
    Then the write player should see "You begin to write on journal."
    And the write player should see "You finish your writing."
    And the write object readable text should not be updated
