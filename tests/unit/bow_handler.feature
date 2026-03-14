Feature: Bow emote input handler
  In order to let players bow in the MUD using natural text commands
  As a developer of the Aethyr engine
  I want the BowHandler to translate textual input into the correct BowCommand objects.

  Background:
    Given a stubbed BowHandler environment

  # ── Lines 36-41: "bow" with no target ──────────────────────────────────────

  Scenario: Bare bow command submits BowCommand with no object
    When the bow handler input is "bow"
    Then the bow handler should have submitted 1 action
    And the submitted bow action should be a BowCommand
    And the submitted bow action object should be nil
    And the submitted bow action post should be nil

  # ── Lines 36-41: "bow <target>" with an object ─────────────────────────────

  Scenario: Bow with a target submits BowCommand with object set
    When the bow handler input is "bow Bob"
    Then the bow handler should have submitted 1 action
    And the submitted bow action should be a BowCommand
    And the submitted bow action object should be "Bob"

  # ── Lines 36-41: "bow <target> (<post>)" with object and post ──────────────

  Scenario: Bow with target and post text submits BowCommand with both
    When the bow handler input is "bow Alice (gracefully)"
    Then the bow handler should have submitted 1 action
    And the submitted bow action should be a BowCommand
    And the submitted bow action object should be "Alice"
    And the submitted bow action post should be "(gracefully)"

  # ── Non-matching input produces no action ──────────────────────────────────

  Scenario: Non-matching input does not submit any action
    When the bow handler input is "wave hello"
    Then the bow handler should have submitted 0 actions
