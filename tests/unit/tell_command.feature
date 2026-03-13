Feature: Tell command action
  In order to enable players to send private tells to each other in the MUD
  As a developer of the Aethyr engine
  I want the TellCommand to correctly validate targets, format messages, and deliver tells.

  Background:
    Given a stubbed TellCommand environment

  # ── Early-exit branches ──────────────────────────────────────────────────

  Scenario: Target not found outputs cannot send tell
    When the tell player sends "hello" to an unknown target "ghost"
    Then the tell player should see "You can't send a tell to ghost."

  Scenario: Target is not a Player outputs cannot send tell
    When the tell player sends "hello" to a non-player target "npc_bob"
    Then the tell player should see "You can't send a tell to npc_bob."

  Scenario: Target is self outputs talking to yourself
    When the tell player sends "hello" targeting themselves
    Then the tell player should see "Talking to yourself?"

  # ── Punctuation handling ─────────────────────────────────────────────────

  Scenario: Tell without punctuation appends period
    When the tell player sends "hello world" to target "Bob"
    Then the tell player output should contain "Hello world."
    And the tell target output should contain "Hello world."

  Scenario: Tell ending with period keeps punctuation
    When the tell player sends "hello world." to target "Bob"
    Then the tell player output should contain "Hello world."
    And the tell target output should not contain "Hello world.."

  Scenario: Tell ending with exclamation keeps punctuation
    When the tell player sends "hello world!" to target "Bob"
    Then the tell player output should contain "Hello world!"

  Scenario: Tell ending with question mark keeps punctuation
    When the tell player sends "hello world?" to target "Bob"
    Then the tell player output should contain "Hello world?"

  # ── Text transformations ─────────────────────────────────────────────────

  Scenario: First letter is capitalised
    When the tell player sends "hey there." to target "Bob"
    Then the tell player output should contain "Hey there."

  Scenario: Extra whitespace is collapsed
    When the tell player sends "hello   world." to target "Bob"
    Then the tell player output should contain "Hello world."

  Scenario: Leading and trailing whitespace is stripped
    When the tell player sends "  hello world.  " to target "Bob"
    Then the tell target output should contain "hello world."

  # ── Full message delivery ────────────────────────────────────────────────

  Scenario: Successful tell outputs to both player and target
    When the tell player sends "Hello." to target "Bob"
    Then the tell player output should contain "You tell Bob,"
    And the tell player output should contain "<tell>\"Hello.\"</tell>"
    And the tell target output should contain "TestTeller tells you,"
    And the tell target output should contain "<tell>\"Hello.\"</tell>"

  Scenario: Successful tell sets reply_to on target
    When the tell player sends "Hello." to target "Bob"
    Then the tell target reply_to should be "TestTeller"

  # ── Edge cases on early-exit: no output to target ────────────────────────

  Scenario: Target not found does not output to anyone else
    When the tell player sends "hello" to an unknown target "ghost"
    Then the tell target should have received no messages

  Scenario: Target is self does not output to target
    When the tell player sends "hello" targeting themselves
    Then the tell target should have received no messages
