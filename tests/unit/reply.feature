Feature: Reply command action
  In order to let players quickly reply to the last person who sent them a tell
  As a developer of the Aethyr engine
  I want the ReplyCommand to check reply_to and delegate to action_tell.

  Background:
    Given a stubbed ReplyCommand environment

  # ── No one to reply to ───────────────────────────────────────────────────

  Scenario: reply_to is nil outputs error message
    Given the reply player has no reply_to set
    When the reply player performs the reply action
    Then the reply player should see "There is no one to reply to."

  # ── Successful reply ─────────────────────────────────────────────────────

  Scenario: reply_to is set delegates to action_tell
    Given the reply player has reply_to set to "SomePlayer"
    When the reply player performs the reply action
    Then the reply command target should be "SomePlayer"
    And action_tell should have been called with the reply command
