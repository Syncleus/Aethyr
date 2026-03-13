Feature: Taste command action
  In order to let players taste things in the MUD world
  As a developer of the Aethyr engine
  I want the TasteCommand to correctly handle all taste scenarios.

  Background:
    Given a stubbed TasteCommand environment

  # ── Taste self via "me" keyword (lines 17-19) ─────────────────────────────
  Scenario: Taste self using the keyword me
    When the TasteCommand action is invoked with target "me"
    Then the taste player should see "You covertly lick yourself."
    And the taste player should see "Hmm, not bad."

  # ── Taste self via object identity (lines 17-19) ──────────────────────────
  Scenario: Taste self when found object is the player
    Given the taste room contains the player as "myself"
    When the TasteCommand action is invoked with target "myself"
    Then the taste player should see "You covertly lick yourself."
    And the taste player should see "Hmm, not bad."

  # ── Taste non-existent target (lines 20-22) ───────────────────────────────
  Scenario: Taste a target that does not exist
    When the TasteCommand action is invoked with target "ghost"
    Then the taste player should see "What would you like to taste?"

  # ── Taste object with nil taste info (lines 25-28) ────────────────────────
  Scenario: Taste an object that has nil taste info
    Given a taste target object "old bone" with no taste
    When the TasteCommand action is invoked with target "old bone"
    Then the taste event to_player should contain "Sticking your tongue out hesitantly, you taste old bone."
    And the taste event to_player should contain "does not taste that great, but has no particular flavor."
    And the taste event to_target should contain "licks you, apparently in an attempt to find out your flavor."
    And the taste event to_other should contain "hesitantly sticks out"
    And the taste event to_other should contain "licks old bone."
    And the taste room should receive the event

  # ── Taste object with empty taste info (lines 25-28) ──────────────────────
  Scenario: Taste an object that has empty taste info
    Given a taste target object "plain rock" with empty taste
    When the TasteCommand action is invoked with target "plain rock"
    Then the taste event to_player should contain "Sticking your tongue out hesitantly, you taste plain rock."
    And the taste event to_player should contain "does not taste that great, but has no particular flavor."
    And the taste event to_target should contain "licks you"
    And the taste room should receive the event

  # ── Taste object with custom taste info (lines 25-26, 30) ─────────────────
  Scenario: Taste an object that has custom taste info
    Given a taste target object "magic candy" with taste "Explodes with sugary sweetness!"
    When the TasteCommand action is invoked with target "magic candy"
    Then the taste event to_player should contain "Sticking your tongue out hesitantly, you taste magic candy."
    And the taste event to_player should contain "Explodes with sugary sweetness!"
    And the taste event to_target should contain "licks you, apparently in an attempt to find out your flavor."
    And the taste event to_other should contain "hesitantly sticks out"
    And the taste event to_other should contain "licks magic candy."
    And the taste room should receive the event
