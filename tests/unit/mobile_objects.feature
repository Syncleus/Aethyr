Feature: Mobile object behaviour
  The Mobile class is the base for all non-player characters in Aethyr.
  It inherits from LivingObject and includes Reacts and Respawns traits.
  This feature exercises initialization, sensory queries, event output
  routing, the output redirection mechanism, description rendering,
  and damage handling.

  Background:
    Given the Mobile library is loaded

  # ── Initialization ──────────────────────────────────────────────
  Scenario: Mobile initializes with a default short description
    Given a Mobile object is created
    Then the Mobile short_desc should be "A mobile stands here with a blank expression."

  # ── balance= ────────────────────────────────────────────────────
  Scenario: Setting balance updates the balance value
    Given a Mobile object is created
    When the Mobile balance is set to false
    Then the Mobile balance should be false

  Scenario: Setting balance back to true
    Given a Mobile object is created
    When the Mobile balance is set to false
    And the Mobile balance is set to true
    Then the Mobile balance should be true

  # ── blind? ──────────────────────────────────────────────────────
  Scenario: Mobile is never blind
    Given a Mobile object is created
    Then the Mobile blind? should be false

  # ── deaf? ───────────────────────────────────────────────────────
  Scenario: Mobile is never deaf
    Given a Mobile object is created
    Then the Mobile deaf? should be false

  # ── out_event with redirect: target is self ─────────────────────
  Scenario: out_event outputs to_target when target is self
    Given a Mobile object is created
    And the Mobile has redirect_output_to enabled
    When the Mobile receives an out_event where target is self
    Then the Mobile redirected output should include "target-msg"

  # ── out_event with redirect: player is self ─────────────────────
  Scenario: out_event outputs to_player when player is self
    Given a Mobile object is created
    And the Mobile has redirect_output_to enabled
    When the Mobile receives an out_event where player is self
    Then the Mobile redirected output should include "player-msg"

  # ── out_event with redirect: other ──────────────────────────────
  Scenario: out_event outputs to_other for unrelated events
    Given a Mobile object is created
    And the Mobile has redirect_output_to enabled
    When the Mobile receives an out_event where neither target nor player is self
    Then the Mobile redirected output should include "other-msg"

  # ── output with redirect_output_to ──────────────────────────────
  Scenario: output forwards to redirect target when set
    Given a Mobile object is created
    And the Mobile has redirect_output_to enabled
    When the Mobile output is called with "hello world"
    Then the Mobile redirect target should have received "hello world"

  # ── output with redirect_output_to but nil target ───────────────
  Scenario: output does nothing when redirect target object is nil
    Given a Mobile object is created
    And the Mobile has redirect_output_to a missing object
    When the Mobile output is called with "lost message"
    Then the Mobile redirect target should have received nothing

  # ── output without redirect ─────────────────────────────────────
  Scenario: output is a noop without redirect_output_to
    Given a Mobile object is created
    When the Mobile output is called with "silent message"
    Then the Mobile redirect target should have received nothing

  # ── long_desc ───────────────────────────────────────────────────
  Scenario: long_desc includes inventory and equipment
    Given a Mobile object is created
    Then the Mobile long_desc should include "nothing"
    And the Mobile long_desc should include "is holding"
    And the Mobile long_desc should include "not wielding"

  # ── take_damage ─────────────────────────────────────────────────
  Scenario: take_damage reduces health
    Given a Mobile object is created
    When the Mobile takes 30 damage
    Then the Mobile health should be 70

  Scenario: take_damage with type argument reduces health
    Given a Mobile object is created
    When the Mobile takes 50 health damage
    Then the Mobile health should be 50
