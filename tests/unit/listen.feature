Feature: ListenCommand action
  In order to let players listen to things in the MUD world
  As a developer of the Aethyr engine
  I want the ListenCommand to correctly handle all listen scenarios.

  Background:
    Given a stubbed ListenCommand environment

  # ── No target: room has a sound (lines 14-18, 22-24) ─────────────────────
  Scenario: Listen with no target when room has a sound
    Given the listen room has a sound "wind howling through the trees"
    When the ListenCommand action is invoked with no target
    Then the listen event to_player should contain "You listen carefully. wind howling through the trees."
    And the listen event to_other should contain "A look of concentration"
    And the listen event to_other should contain "listens intently"
    And the listen room should receive the event

  # ── No target: room has no sound (lines 14-16, 20, 22-24) ────────────────
  Scenario: Listen with no target when room has no sound
    Given the listen room has no sound
    When the ListenCommand action is invoked with no target
    Then the listen event to_player should contain "You listen carefully but hear nothing unusual."
    And the listen event to_other should contain "A look of concentration"
    And the listen room should receive the event

  # ── Listen to self via object match (lines 14-15, 27, 29-31) ─────────────
  Scenario: Listen to self when object matches player
    When the ListenCommand action is invoked targeting self
    Then the listen player should see "Listening quietly, you can faintly hear your pulse."

  # ── Listen to self via "me" keyword (lines 14-15, 27, 29-31) ─────────────
  Scenario: Listen using the keyword me
    When the ListenCommand action is invoked with target "me"
    Then the listen player should see "Listening quietly, you can faintly hear your pulse."

  # ── Listen to unknown target (lines 14-15, 27, 29, 32-34) ────────────────
  Scenario: Listen to a target that does not exist
    When the ListenCommand action is invoked with unknown target "ghost"
    Then the listen player should see "What would you like to listen to?"

  # ── Listen to object with no sound (lines 14-15, 27, 29, 37-40, 44-46) ──
  Scenario: Listen to an object that has no sound
    Given a listen target object "old sword" with no sound
    When the ListenCommand action is invoked with target "old sword"
    Then the listen event to_player should contain "You bend your head towards old sword."
    And the listen event to_player should contain "emits no unusual sounds."
    And the listen event to_target should contain "listens to you carefully."
    And the listen event to_other should contain "bends"
    And the listen event to_other should contain "listens"
    And the listen room should receive the event

  # ── Listen to object with a sound (lines 14-15, 27, 29, 37-39, 42, 44-46)
  Scenario: Listen to an object that has a sound
    Given a listen target object "music box" with sound "a gentle melody"
    When the ListenCommand action is invoked with target "music box"
    Then the listen event to_player should contain "You bend your head towards music box."
    And the listen event to_player should contain "a gentle melody"
    And the listen event to_target should contain "listens to you carefully."
    And the listen event to_other should contain "bends"
    And the listen room should receive the event

  # ── Listen to object with empty string sound (lines 37-40) ───────────────
  Scenario: Listen to an object that has an empty sound string
    Given a listen target object "plain rock" with empty sound
    When the ListenCommand action is invoked with target "plain rock"
    Then the listen event to_player should contain "You bend your head towards plain rock."
    And the listen event to_player should contain "emits no unusual sounds."
    And the listen room should receive the event
