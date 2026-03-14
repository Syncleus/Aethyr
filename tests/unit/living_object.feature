Feature: LivingObject base class
  The LivingObject class is the shared parent of Player and Mobile.
  It provides wear, remove, take_damage, and death_message behaviour.
  These scenarios exercise the methods defined in living.rb directly.

  Background:
    Given the LivingObject test dependencies are loaded

  # ── wear: check_position fails ──────────────────────────────────
  Scenario: wear returns false when check_position reports an error
    Given a LivingObject is created
    And a wearable item "helmet" at position "head" layer 0 exists
    And the equipment check_position will return "You cannot wear that here."
    When I call wear on the LivingObject with item "helmet"
    Then the LivingObject wear result should be false
    And the LivingObject output should include "You cannot wear that here."

  # ── wear: check_position passes and equipment.wear succeeds ─────
  Scenario: wear returns true when equipment accepts the item
    Given a LivingObject is created
    And a wearable item "helmet" at position "head" layer 0 exists
    And the equipment check_position will return nil
    And the equipment wear will succeed for item "helmet"
    And the LivingObject inventory contains item "helmet"
    When I call wear on the LivingObject with item "helmet"
    Then the LivingObject wear result should be true
    And the LivingObject inventory should not contain item "helmet"

  # ── wear: check_position passes but equipment.wear fails ────────
  Scenario: wear returns false when equipment.wear fails
    Given a LivingObject is created
    And a wearable item "helmet" at position "head" layer 0 exists
    And the equipment check_position will return nil
    And the equipment wear will fail
    When I call wear on the LivingObject with item "helmet"
    Then the LivingObject wear result should be false

  # ── remove: equipment.remove succeeds ───────────────────────────
  Scenario: remove returns true and adds item to inventory
    Given a LivingObject is created
    And a wearable item "helmet" at position "head" layer 0 exists
    And the equipment remove will succeed for item "helmet"
    When I call remove on the LivingObject with item "helmet"
    Then the LivingObject remove result should be true
    And the LivingObject inventory should contain item "helmet"

  # ── remove: equipment.remove fails ──────────────────────────────
  Scenario: remove returns false when item is not equipped
    Given a LivingObject is created
    And a wearable item "helmet" at position "head" layer 0 exists
    And the equipment remove will fail
    When I call remove on the LivingObject with item "helmet"
    Then the LivingObject remove result should be false

  # ── take_damage: health clamped to zero ─────────────────────────
  Scenario: take_damage clamps health to zero when damage exceeds current health
    Given a LivingObject is created
    When I call take_damage on the LivingObject with amount 150 and type health
    Then the LivingObject health should be 0

  # ── take_damage: stamina normal ─────────────────────────────────
  Scenario: take_damage reduces stamina
    Given a LivingObject is created
    And the LivingObject has stamina set to 80
    When I call take_damage on the LivingObject with amount 30 and type stamina
    Then the LivingObject stamina should be 50

  # ── take_damage: stamina clamped to zero ────────────────────────
  Scenario: take_damage clamps stamina to zero when damage exceeds current stamina
    Given a LivingObject is created
    And the LivingObject has stamina set to 20
    When I call take_damage on the LivingObject with amount 50 and type stamina
    Then the LivingObject stamina should be 0

  # ── take_damage: fortitude normal ───────────────────────────────
  Scenario: take_damage reduces fortitude
    Given a LivingObject is created
    And the LivingObject has fortitude set to 60
    When I call take_damage on the LivingObject with amount 25 and type fortitude
    Then the LivingObject fortitude should be 35

  # ── take_damage: fortitude clamped to zero ──────────────────────
  Scenario: take_damage clamps fortitude to zero when damage exceeds current fortitude
    Given a LivingObject is created
    And the LivingObject has fortitude set to 10
    When I call take_damage on the LivingObject with amount 30 and type fortitude
    Then the LivingObject fortitude should be 0

  # ── take_damage: unknown type ───────────────────────────────────
  Scenario: take_damage logs a message for unknown damage type
    Given a LivingObject is created
    When I call take_damage on the LivingObject with amount 10 and type magic
    Then the LivingObject should have logged unknown damage type "magic"

  # ── death_message: custom ───────────────────────────────────────
  Scenario: death_message returns custom message when set
    Given a LivingObject is created
    And the LivingObject has a custom death_message "The creature dissolves into dust."
    When I call death_message on the LivingObject
    Then the LivingObject death_message result should be "The creature dissolves into dust."

  # ── death_message: default ──────────────────────────────────────
  Scenario: death_message returns default message when none is set
    Given a LivingObject is created
    When I call death_message on the LivingObject
    Then the LivingObject death_message result should include "last bit of spark"
