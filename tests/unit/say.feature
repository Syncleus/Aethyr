Feature: Say command action
  In order to enable players to speak to each other in the MUD
  As a developer of the Aethyr engine
  I want the SayCommand to correctly format and broadcast speech messages.

  Background:
    Given a stubbed SayCommand environment

  # ── Early-exit branches ──────────────────────────────────────────────────

  Scenario: Phrase is nil outputs Huh?
    When the player says with no phrase
    Then the say player should see "Huh?"

  Scenario: Target specified but not found outputs Say what to whom?
    When the player says "hello" to an unknown target "ghost"
    Then the say player should see "Say what to whom?"

  Scenario: Target is self outputs Talking to yourself again?
    When the player says "hello" targeting themselves
    Then the say player should see "Talking to yourself again?"

  # ── Punctuation detection without target ─────────────────────────────────

  Scenario: Say with period ending and no target
    When the player says "Hello world." with no target
    Then the say event to_player should contain "you say,"
    And the say event to_other should contain "TestPlayer says,"
    And the say event to_player should contain "Hello world."
    And the room should receive the event

  Scenario: Say with exclamation ending and no target
    When the player says "Hello world!" with no target
    Then the say event to_player should contain "you exclaim,"
    And the say event to_other should contain "TestPlayer exclaims,"
    And the room should receive the event

  Scenario: Say with question ending and no target
    When the player says "Hello world?" with no target
    Then the say event to_player should contain "you ask,"
    And the say event to_other should contain "TestPlayer asks,"
    And the room should receive the event

  Scenario: Say with no punctuation ending and no target
    When the player says "Hello world" with no target
    Then the say event to_player should contain "you say,"
    And the say event to_other should contain "TestPlayer says,"
    And the say event phrase should end with a period inside quotes
    And the room should receive the event

  # ── No target path message fields ────────────────────────────────────────

  Scenario: No target sets blind and deaf fields
    When the player says "Hello world." with no target
    Then the say event to_blind_other should contain "Someone says,"
    And the say event to_deaf_target should contain "You see TestPlayer say something."
    And the say event to_deaf_other should contain "You see TestPlayer say something."

  # ── Target with ask (question, no emoticon) ──────────────────────────────

  Scenario: Say question to a target triggers ask path
    When the player says "How are you?" to target "Bob"
    Then the say event to_target should contain "TestPlayer asks you,"
    And the say event to_player should contain "you ask Bob,"
    And the say event to_other should contain "TestPlayer asks Bob,"
    And the say event to_blind_target should contain "Someone asks,"
    And the say event to_blind_other should contain "Someone asks,"
    And the say event to_deaf_target should contain "seems to be asking you something"
    And the say event to_deaf_other should contain "seems to be asking Bob something"
    And the room should receive the event

  # ── Target with non-ask (exclamation) ────────────────────────────────────

  Scenario: Say exclamation to a target triggers non-ask target path
    When the player says "Watch out!" to target "Bob"
    Then the say event to_target should contain "TestPlayer exclaims to you,"
    And the say event to_player should contain "you exclaim to Bob,"
    And the say event to_other should contain "TestPlayer exclaims to Bob,"
    And the say event to_blind_target should contain "Someone exclaims,"
    And the say event to_blind_other should contain "Someone exclaims,"
    And the say event to_deaf_target should contain "You see TestPlayer say something to you."
    And the say event to_deaf_other should contain "You see TestPlayer say something to Bob."
    And the room should receive the event

  # ── Emoticon handling ────────────────────────────────────────────────────

  Scenario: Smiley emoticon sets smile voice
    When the player says "Hello :)" with no target
    Then the say event to_player should contain "smile and say,"
    And the say event to_other should contain "smiles and says,"

  Scenario: Frown emoticon sets frown voice
    When the player says "Hello :(" with no target
    Then the say event to_player should contain "frown and say,"
    And the say event to_other should contain "frowns and says,"

  Scenario: Laugh emoticon sets laugh voice
    When the player says "Hello :D" with no target
    Then the say event to_player should contain "laugh as you say,"
    And the say event to_other should contain "laughs as he says,"

  # ── Prefix handling ──────────────────────────────────────────────────────

  Scenario: Prefix is prepended with comma separator
    When the player says "Hello." with prefix "Smiling" and no target
    Then the say event to_player should start with "Smiling, "

  Scenario: No prefix uses empty string
    When the player says "Hello." with no target
    Then the say event to_player should not start with ","

  # ── Text transformations ─────────────────────────────────────────────────

  Scenario: First letter is capitalised
    When the player says "hello world." with no target
    Then the say event phrase should contain "Hello world."

  Scenario: Standalone i is capitalised to I
    When the player says "i think i can." with no target
    Then the say event phrase should contain "I think I can."

  Scenario: Message type is set to chat
    When the player says "Hello." with no target
    Then the say event message_type should be chat
