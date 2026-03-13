Feature: Feel command action
  In order to let players feel things in the MUD world
  As a developer of the Aethyr engine
  I want the FeelCommand to correctly handle all feel scenarios.

  Background:
    Given a stubbed FeelCommand environment

  # ── Feel self via "me" keyword (lines 17-19) ──────────────────────────────
  Scenario: Feel self using the keyword me
    When the FeelCommand action is invoked with target "me"
    Then the feel player should see "You feel fine."

  # ── Feel non-existent object (lines 20-22) ─────────────────────────────────
  Scenario: Feel a target that does not exist
    When the FeelCommand action is invoked with unknown target "ghost"
    Then the feel player should see "What would you like to feel?"

  # ── Feel object with nil texture (lines 25-28, 32-34) ─────────────────────
  Scenario: Feel an object that has no texture
    Given a feel target object "old sword" with no texture
    When the FeelCommand action is invoked with target "old sword"
    Then the feel event to_player should contain "You reach out your hand and gingerly feel old sword."
    And the feel event to_player should contain "Its texture is what you would expect."
    And the feel event to_target should contain "reaches out a hand and gingerly touches you."
    And the feel event to_other should contain "reaches out his hand and touches old sword."
    And the feel room should receive the event

  # ── Feel object with empty string texture (lines 25-28, 32-34) ─────────────
  Scenario: Feel an object that has an empty texture string
    Given a feel target object "plain rock" with empty texture
    When the FeelCommand action is invoked with target "plain rock"
    Then the feel event to_player should contain "You reach out your hand and gingerly feel plain rock."
    And the feel event to_player should contain "Its texture is what you would expect."
    And the feel room should receive the event

  # ── Feel object with custom texture (lines 25-26, 29-30, 32-34) ────────────
  Scenario: Feel an object that has a custom texture
    Given a feel target object "silk robe" with texture "Smooth and cool to the touch."
    When the FeelCommand action is invoked with target "silk robe"
    Then the feel event to_player should contain "You reach out your hand and gingerly feel silk robe."
    And the feel event to_player should contain "Smooth and cool to the touch."
    And the feel event to_target should contain "reaches out a hand and gingerly touches you."
    And the feel event to_other should contain "reaches out his hand and touches silk robe."
    And the feel room should receive the event
