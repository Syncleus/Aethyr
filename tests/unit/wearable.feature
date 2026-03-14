Feature: Wearable trait
  The Wearable module provides position and layer accessors with safe
  defaults.  These scenarios exercise the fallback branches that fire
  when the underlying info attributes are nil.

  # ── position: normal value ──────────────────────────────────────
  Scenario: position returns info.position when set
    Given I require the Wearable test dependencies
    When I create a wearable test object
    Then the wearable position should be :feet

  # ── position: nil fallback (line 23) ────────────────────────────
  Scenario: position returns nil when info.position is nil
    Given I require the Wearable test dependencies
    When I create a wearable test object
    And I set the wearable info position to nil
    Then the wearable position should be nil

  # ── layer: normal value ─────────────────────────────────────────
  Scenario: layer returns info.layer when set
    Given I require the Wearable test dependencies
    When I create a wearable test object
    Then the wearable layer should be 2

  # ── layer: nil fallback (line 28) ───────────────────────────────
  Scenario: layer returns default 2 when info.layer is nil
    Given I require the Wearable test dependencies
    When I create a wearable test object
    And I set the wearable info layer to nil
    Then the wearable layer should be 2
