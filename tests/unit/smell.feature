Feature: Smell command action
  In order to let players smell things in the MUD world
  As a developer of the Aethyr engine
  I want the SmellCommand to correctly handle all smell scenarios.

  Background:
    Given a stubbed SmellCommand environment

  # ── No target: room has a smell (lines 13-16, 20-22) ─────────────────────
  Scenario: Smell with no target when room has a smell
    Given the smell room has a smell "roses and lavender"
    When the SmellCommand action is invoked with no target
    Then the smell event to_player should contain "You sniff the air. roses and lavender."
    And the smell event to_other should contain "sniffs the air."
    And the smell room should receive the event

  # ── No target: room has no smell (lines 13-14, 18, 20-22) ────────────────
  Scenario: Smell with no target when room has no smell
    Given the smell room has no smell
    When the SmellCommand action is invoked with no target
    Then the smell event to_player should contain "You sniff the air, but detect no unusual aromas."
    And the smell event to_other should contain "sniffs the air."
    And the smell room should receive the event

  # ── Smell self: revolting stench (lines 25, 27-32, 37-38) ────────────────
  Scenario: Smell self triggers revolting stench when rand > 0.6
    When the SmellCommand action is invoked targeting self with high rand
    Then the smell event to_player should contain "You cautiously sniff your armpits."
    And the smell event to_player should contain "Your head snaps back"
    And the smell event to_other should contain "recoils in horror"
    And the smell room should receive the event

  # ── Smell self: not too bad (lines 25, 27-29, 34-35, 37-38) ─────────────
  Scenario: Smell self triggers not too bad when rand <= 0.6
    When the SmellCommand action is invoked targeting self with low rand
    Then the smell event to_player should contain "You cautiously sniff your armpits."
    And the smell event to_player should contain "Meh, not too bad."
    And the smell event to_other should contain "shrugs, apparently unconcerned"
    And the smell room should receive the event

  # ── Smell target not found (lines 25, 39-41) ────────────────────────────
  Scenario: Smell a target that does not exist
    When the SmellCommand action is invoked with unknown target "ghost"
    Then the smell player should see "What are you trying to smell?"

  # ── Smell valid object with no smell (lines 25, 44-47, 51-53) ────────────
  Scenario: Smell an object that has no particular aroma
    Given a smell target object "old sword" with no smell
    When the SmellCommand action is invoked with target "old sword"
    Then the smell event to_player should contain "Leaning in slightly, you sniff old sword."
    And the smell event to_player should contain "has no particular aroma."
    And the smell event to_target should contain "sniffs you curiously"
    And the smell event to_other should contain "thrusts"
    And the smell room should receive the event

  # ── Smell valid object with a smell (lines 25, 44-46, 49, 51-53) ─────────
  Scenario: Smell an object that has a smell
    Given a smell target object "fragrant flower" with smell "sweet nectar"
    When the SmellCommand action is invoked with target "fragrant flower"
    Then the smell event to_player should contain "Leaning in slightly, you sniff fragrant flower."
    And the smell event to_player should contain "sweet nectar"
    And the smell event to_target should contain "sniffs you curiously"
    And the smell event to_other should contain "thrusts"
    And the smell room should receive the event

  # ── Smell valid object with empty string smell (lines 25, 44-47, 51-53) ──
  Scenario: Smell an object that has an empty smell string
    Given a smell target object "plain rock" with empty smell
    When the SmellCommand action is invoked with target "plain rock"
    Then the smell event to_player should contain "Leaning in slightly, you sniff plain rock."
    And the smell event to_player should contain "has no particular aroma."
    And the smell room should receive the event

  # ── Smell via "me" keyword (lines 25, 27-28) ────────────────────────────
  Scenario: Smell using the keyword me
    When the SmellCommand action is invoked with target "me" and low rand
    Then the smell event to_player should contain "You cautiously sniff your armpits."
    And the smell room should receive the event
