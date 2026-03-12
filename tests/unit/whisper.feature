Feature: Whisper command action
  In order to enable players to whisper privately to each other in the MUD
  As a developer of the Aethyr engine
  I want the WhisperCommand to correctly format and deliver whisper messages.

  Background:
    Given a stubbed WhisperCommand environment

  # ── Early-exit branches ──────────────────────────────────────────────────

  Scenario: Target not found outputs To whom message
    When the player whispers "hello" to an unknown target "ghost"
    Then the whisper player should see "To whom are you trying to whisper?"

  Scenario: Whisper to self outputs self-whisper message
    When the player whispers "hello" targeting themselves
    Then the whisper player should see "Whispering to yourself again?"
    And the whisper event to_other should contain "whispers to himself"
    And the whisper room should receive the self-whisper event

  Scenario: Phrase is nil outputs What are you trying message
    When the player whispers with no phrase to target "Bob"
    Then the whisper player should see "What are you trying to whisper?"

  # ── Prefix handling ──────────────────────────────────────────────────────

  Scenario: Prefix is prepended with comma separator
    When the player whispers "Hello." with prefix "Softly" to target "Bob"
    Then the whisper event to_player should start with "Softly, "

  Scenario: No prefix uses empty string
    When the player whispers "Hello." to target "Bob"
    Then the whisper event to_player should not start with ","

  # ── Punctuation detection ────────────────────────────────────────────────

  Scenario: Whisper with no punctuation adds period
    When the player whispers "Hello world" to target "Bob"
    Then the whisper event to_player phrase should end with a period inside quotes

  Scenario: Whisper with period ending does not add extra period
    When the player whispers "Hello world." to target "Bob"
    Then the whisper event to_player phrase should not have double period

  Scenario: Whisper with exclamation ending does not add period
    When the player whispers "Hello world!" to target "Bob"
    Then the whisper event to_player phrase should contain "Hello world!"

  Scenario: Whisper with question ending does not add period
    When the player whispers "Hello world?" to target "Bob"
    Then the whisper event to_player phrase should contain "Hello world?"

  # ── Text transformations ─────────────────────────────────────────────────

  Scenario: First letter is capitalised
    When the player whispers "hello world." to target "Bob"
    Then the whisper event to_player phrase should contain "Hello world."

  # ── Full message fields ──────────────────────────────────────────────────

  Scenario: Normal whisper sets all event fields
    When the player whispers "Hello." to target "Bob"
    Then the whisper event target should be the target object
    And the whisper event to_player should contain "you whisper to Bob"
    And the whisper event to_target should contain "TestWhisperer whispers to you"
    And the whisper event to_other should contain "TestWhisperer whispers quietly into Bob's ear."
    And the whisper event to_other_blind should contain "TestWhisperer whispers."
    And the whisper event to_target_blind should contain "Someone whispers to you"
    And the whisper room should receive the event
