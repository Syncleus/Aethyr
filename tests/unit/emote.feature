Feature: EmoteCommand action
  In order to let players express custom emotes in the MUD
  As a developer of the Aethyr engine
  I want EmoteCommand#action to correctly format and broadcast emote messages.

  Background:
    Given a stubbed EmoteCommand environment

  # ── Simple emote (no $ substitution) – lines 15-17, 19-20, 43, 46-50 ──

  Scenario: Simple emote without punctuation appends period
    When the player emotes "waves"
    Then the emote event to_player should be "You emote: TestPlayer waves."
    And the emote event to_other should be "TestPlayer waves."
    And the emote event message_type should be chat
    And the emote room should receive the event

  Scenario: Simple emote ending with period keeps punctuation
    When the player emotes "waves."
    Then the emote event to_player should be "You emote: TestPlayer waves."
    And the emote event to_other should be "TestPlayer waves."

  Scenario: Simple emote ending with exclamation keeps punctuation
    When the player emotes "waves!"
    Then the emote event to_player should be "You emote: TestPlayer waves!"
    And the emote event to_other should be "TestPlayer waves!"

  Scenario: Simple emote ending with question mark keeps punctuation
    When the player emotes "waves?"
    Then the emote event to_player should be "You emote: TestPlayer waves?"
    And the emote event to_other should be "TestPlayer waves?"

  Scenario: Simple emote ending with double quote keeps punctuation
    When the player emotes 'says "hello"'
    Then the emote event to_other should contain 'says "hello"'

  # ── $me substitution – lines 23-26, 46-50 ──────────────────────────────

  Scenario: Emote with $me replaces with player name and capitalizes
    When the player emotes "$me waves happily"
    Then the emote event to_player should be "You emote: TestPlayer waves happily."
    And the emote event to_other should be "TestPlayer waves happily."
    And the emote event message_type should be chat
    And the emote room should receive the event

  Scenario: Emote with $Me (mixed case) replaces with player name
    When the player emotes "$Me grins"
    Then the emote event to_other should be "TestPlayer grins."

  # ── $target substitution – lines 27-33, 35-37, 40-41 ───────────────────

  Scenario: Emote with $target found in room outputs to target and room
    Given a target named "Bob" exists in the emote room
    When the player emotes "hugs $Bob tightly"
    Then the emote target "Bob" should see "TestPlayer hugs you tightly."
    And the emote room should receive output "TestPlayer hugs Bob tightly."
    And the emote player should see "You emote: TestPlayer hugs Bob tightly."

  Scenario: Emote with $target not found replaces with no one
    When the player emotes "hugs $Ghost tightly"
    Then the emote player should see "You emote: TestPlayer hugs no one tightly."
    And the emote room should receive output "TestPlayer hugs no one tightly."

  Scenario: Emote with $target who is blind skips their output
    Given a blind target named "Alice" exists in the emote room
    When the player emotes "winks at $Alice"
    Then the emote target "Alice" should not see anything
    And the emote room should receive output "TestPlayer winks at Alice."

  Scenario: Emote with $target who is not blind gets output
    Given a sighted target named "Carol" exists in the emote room
    When the player emotes "waves at $Carol"
    Then the emote target "Carol" should see "TestPlayer waves at you."
