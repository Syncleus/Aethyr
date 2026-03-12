Feature: Reactor behaviour
  The Reactor class is the scripting mechanism for Mobiles in Aethyr.
  Reactions consist of an action to match, a test condition, and a
  reaction body. This feature exercises all Reactor methods including
  initialization, adding/removing reactions, event handling, file
  loading, listing, and error paths.

  Background:
    Given the Reactor library is loaded

  # ── Initialization ──────────────────────────────────────────────
  Scenario: Reactor initializes with zero reactions
    Given a Reactor object is created with a mock mob
    Then the Reactor to_s should report 0 reactions

  # ── Adding single-action reactions ─────────────────────────────
  Scenario: Reactor adds a valid single-action reaction
    Given a Reactor object is created with a mock mob
    When a Reactor reaction with action "say" test "true" and reaction "\"hello\"" is added
    Then the Reactor to_s should report 1 reactions

  # ── Adding multi-action reactions ──────────────────────────────
  Scenario: Reactor adds a valid multi-action reaction
    Given a Reactor object is created with a mock mob
    When a Reactor reaction with actions "say,emote" test "true" and reaction "\"wave\"" is added
    Then the Reactor to_s should report 2 reactions

  # ── Rejecting invalid reactions ────────────────────────────────
  Scenario: Reactor rejects a reaction missing the test field
    Given a Reactor object is created with a mock mob
    When a Reactor reaction missing the test field is added
    Then the Reactor to_s should report 0 reactions

  Scenario: Reactor rejects a reaction missing the action field
    Given a Reactor object is created with a mock mob
    When a Reactor reaction missing the action field is added
    Then the Reactor to_s should report 0 reactions

  Scenario: Reactor rejects a reaction missing the reaction field
    Given a Reactor object is created with a mock mob
    When a Reactor reaction missing the reaction field is added
    Then the Reactor to_s should report 0 reactions

  # ── add_all ────────────────────────────────────────────────────
  Scenario: Reactor add_all registers multiple reactions
    Given a Reactor object is created with a mock mob
    When a Reactor batch of 2 valid reactions is added
    Then the Reactor to_s should report 2 reactions

  # ── react_to: matching action with passing test ────────────────
  Scenario: Reactor reacts to an event whose test passes
    Given a Reactor object is created with a mock mob
    And a Reactor reaction with action "say" test "true" and reaction "\"say hello\"" is added
    When the Reactor reacts to an event with action "say"
    Then the Reactor commands should include "say hello"

  # ── react_to: matching action with failing test ────────────────
  Scenario: Reactor does not react when the test fails
    Given a Reactor object is created with a mock mob
    And a Reactor reaction with action "say" test "false" and reaction "\"say hello\"" is added
    When the Reactor reacts to an event with action "say"
    Then the Reactor commands should be empty

  # ── react_to: no matching action ───────────────────────────────
  Scenario: Reactor returns empty commands for unregistered actions
    Given a Reactor object is created with a mock mob
    And a Reactor reaction with action "say" test "true" and reaction "\"say hello\"" is added
    When the Reactor reacts to an event with action "look"
    Then the Reactor commands should be empty

  # ── react_to: event supplies its own player ────────────────────
  Scenario: Reactor uses event player when provided
    Given a Reactor object is created with a mock mob
    And a Reactor reaction with action "say" test "true" and reaction "\"greet\"" is added
    When the Reactor reacts to an event with action "say" and a custom player
    Then the Reactor commands should include "greet"

  # ── react_to: reaction body raises an exception ────────────────
  Scenario: Reactor catches exceptions from reaction bodies
    Given a Reactor object is created with a mock mob
    And a Reactor reaction with action "say" test "true" and reaction "raise 'kaboom'" is added
    When the Reactor reacts to an event with action "say"
    Then the Reactor commands should be empty

  # ── react_to: reaction returns empty string ────────────────────
  Scenario: Reactor ignores empty string results from reactions
    Given a Reactor object is created with a mock mob
    And a Reactor reaction with action "say" test "true" and reaction "\"\"" is added
    When the Reactor reacts to an event with action "say"
    Then the Reactor commands should be empty

  # ── react_to: reaction returns non-string ──────────────────────
  Scenario: Reactor ignores non-string results from reactions
    Given a Reactor object is created with a mock mob
    And a Reactor reaction with action "say" test "true" and reaction "42" is added
    When the Reactor reacts to an event with action "say"
    Then the Reactor commands should be empty

  # ── react_to: reaction returns nil ─────────────────────────────
  Scenario: Reactor ignores nil results from reactions
    Given a Reactor object is created with a mock mob
    And a Reactor reaction with action "say" test "true" and reaction "nil" is added
    When the Reactor reacts to an event with action "say"
    Then the Reactor commands should be empty

  # ── react_to: test itself raises (outer rescue) ────────────────
  Scenario: Reactor returns nil when the test proc raises an exception
    Given a Reactor object is created with a mock mob
    And a Reactor reaction with a broken test proc is added
    When the Reactor reacts to an event with action "say"
    Then the Reactor react_to result should be nil

  # ── react_to: multiple matching reactions ──────────────────────
  Scenario: Reactor fires all matching reactions for the same action
    Given a Reactor object is created with a mock mob
    And a Reactor reaction with action "say" test "true" and reaction "\"first\"" is added
    And a Reactor reaction with action "say" test "true" and reaction "\"second\"" is added
    When the Reactor reacts to an event with action "say"
    Then the Reactor commands should include "first"
    And the Reactor commands should include "second"

  # ── list_reactions: single action ──────────────────────────────
  Scenario: Reactor lists reactions with a single action
    Given a Reactor object is created with a mock mob
    And a Reactor reaction with action "say" test "true" and reaction "\"hello\"" is added
    Then the Reactor list_reactions should mention action "say"
    And the Reactor list_reactions should include the test source
    And the Reactor list_reactions should include the reaction source

  # ── list_reactions: array action ───────────────────────────────
  Scenario: Reactor lists reactions with array actions
    Given a Reactor object is created with a mock mob
    And a Reactor reaction with actions "say,emote" test "true" and reaction "\"wave\"" is added
    Then the Reactor list_reactions should mention action "say"
    And the Reactor list_reactions should mention action "emote"

  # ── list_reactions: empty ──────────────────────────────────────
  Scenario: Reactor list_reactions is empty when no reactions exist
    Given a Reactor object is created with a mock mob
    Then the Reactor list_reactions should be blank

  # ── clear ──────────────────────────────────────────────────────
  Scenario: Reactor clear removes all reactions
    Given a Reactor object is created with a mock mob
    And a Reactor reaction with action "say" test "true" and reaction "\"hello\"" is added
    When the Reactor reactions are cleared
    Then the Reactor to_s should report 0 reactions

  # ── load from .rx file ─────────────────────────────────────────
  Scenario: Reactor loads reactions from an rx file
    Given a Reactor object is created with a mock mob
    And a Reactor test rx file exists with single and multi-action reactions
    When the Reactor loads the test rx file
    Then the Reactor to_s should report at least 2 reactions
    And the Reactor list_reactions should mention action "greet"
    And the Reactor list_reactions should mention action "hug"
    And the Reactor list_reactions should mention action "kiss"

  # ── load from .rx file with comments and blank lines ───────────
  Scenario: Reactor load skips comments and blank lines in rx files
    Given a Reactor object is created with a mock mob
    And a Reactor test rx file exists with comments and blanks
    When the Reactor loads the test rx file
    Then the Reactor to_s should report 1 reactions
