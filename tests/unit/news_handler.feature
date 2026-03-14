Feature: News command input handler
  In order to interact with newsboards using natural commands
  As a player
  I want the News input handler to translate my textual input into the correct command objects.

  Background:
    Given a stubbed NewsHandler environment

  # ── Line 71: bare "news" → LatestNewsCommand (already covered) ──────────────

  Scenario: Bare news command submits LatestNewsCommand
    When the news handler input is "news"
    Then the news handler should have submitted 1 action
    And the submitted news action should be a LatestNewsCommand

  # ── Lines 73-74: "news <id>" → ReadPostCommand ─────────────────────────────

  Scenario: news followed by a number submits ReadPostCommand
    When the news handler input is "news 5"
    Then the news handler should have submitted 1 action
    And the submitted news action should be a ReadPostCommand
    And the submitted news action post_id should be "5"

  Scenario: news read followed by a number submits ReadPostCommand
    When the news handler input is "news read 12"
    Then the news handler should have submitted 1 action
    And the submitted news action should be a ReadPostCommand
    And the submitted news action post_id should be "12"

  # ── Lines 76-77: "news reply to <id>" → WritePostCommand with reply_to ─────

  Scenario: news reply to a post number submits WritePostCommand with reply_to
    When the news handler input is "news reply to  3"
    Then the news handler should have submitted 1 action
    And the submitted news action should be a WritePostCommand
    And the submitted news action reply_to should be "3"

  Scenario: news reply without "to" submits WritePostCommand with reply_to
    When the news handler input is "news reply 7"
    Then the news handler should have submitted 1 action
    And the submitted news action should be a WritePostCommand
    And the submitted news action reply_to should be "7"

  # ── Line 79: "news unread" → ListUnreadCommand ─────────────────────────────

  Scenario: news unread submits ListUnreadCommand
    When the news handler input is "news unread"
    Then the news handler should have submitted 1 action
    And the submitted news action should be a ListUnreadCommand

  # ── Lines 81-82: "news last <n>" → LatestNewsCommand with limit ────────────

  Scenario: news last followed by a number submits LatestNewsCommand with limit
    When the news handler input is "news last 10"
    Then the news handler should have submitted 1 action
    And the submitted news action should be a LatestNewsCommand
    And the submitted news action limit should be 10

  # ── Lines 84-85: "news delete <id>" → DeletePostCommand ────────────────────

  Scenario: news delete followed by a number submits DeletePostCommand
    When the news handler input is "news delete 4"
    Then the news handler should have submitted 1 action
    And the submitted news action should be a DeletePostCommand
    And the submitted news action post_id should be "4"

  # ── Line 87: "news write" → WritePostCommand (no reply_to) ─────────────────

  Scenario: news write submits WritePostCommand without reply_to
    When the news handler input is "news write"
    Then the news handler should have submitted 1 action
    And the submitted news action should be a WritePostCommand
    And the submitted news action should not have reply_to

  # ── Line 89: "news all" → AllCommand ───────────────────────────────────────

  Scenario: news all submits AllCommand
    When the news handler input is "news all"
    Then the news handler should have submitted 1 action
    And the submitted news action should be an AllCommand

  # ── Non-matching input produces no action ──────────────────────────────────

  Scenario: Non-matching input does not submit any action
    When the news handler input is "look around"
    Then the news handler should have submitted 0 actions
