Feature: ReadPostCommand action
  In order to let players read posts from in-game bulletin boards
  As a developer of the Aethyr engine
  I want the ReadPostCommand to correctly handle all reading branches.

  Background:
    Given a stubbed ReadPostCommand environment

  # ── Branch 1: no board found (lines 19-21) ──────────────────────────────────

  Scenario: No board in the room outputs an error
    Given the rpost board lookup will return nil
    When the rpost read post command is invoked
    Then the rpost player should see "There do not seem to be any postings here."

  # ── Branch 2: board found but post not found (lines 24-27) ──────────────────

  Scenario: Post not found outputs an error
    Given the rpost board lookup will return a board
    And the rpost board will return nil for the requested post
    When the rpost read post command is invoked
    Then the rpost player should see "No such posting here."

  # ── Branch 3: board and post found, player.info.boards is nil (lines 30-36) ─

  Scenario: Reading a post when player boards hash is nil
    Given the rpost board lookup will return a board
    And the rpost board will return a post for the requested post
    And the rpost player info boards is nil
    When the rpost read post command is invoked
    Then the rpost player info boards should be initialized
    And the rpost player info boards should track the post id for the board
    And the rpost player should see the post content

  # ── Branch 4: board and post found, player.info.boards already exists (lines 34-36)

  Scenario: Reading a post when player boards hash already exists
    Given the rpost board lookup will return a board
    And the rpost board will return a post for the requested post
    And the rpost player info boards already exists
    When the rpost read post command is invoked
    Then the rpost player info boards should track the post id for the board
    And the rpost player should see the post content
