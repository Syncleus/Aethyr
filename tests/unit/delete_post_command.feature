Feature: DeletePostCommand action
  In order to let players delete their own posts from in-game bulletin boards
  As a developer of the Aethyr engine
  I want the DeletePostCommand to correctly handle all deletion branches.

  Background:
    Given a stubbed DeletePostCommand environment

  # ── Branch 1: no board found (lines 23-25) ──────────────────────────────────

  Scenario: No board in the room outputs an error
    Given the dpost board lookup will return nil
    When the dpost delete post command is invoked
    Then the dpost player should see "What newsboard are you talking about?"

  # ── Branch 2: board found but post not found (lines 30-31) ──────────────────

  Scenario: Post not found outputs an error
    Given the dpost board lookup will return a board
    And the dpost board has no post for the requested id
    When the dpost delete post command is invoked
    Then the dpost player should see "No such post."

  # ── Branch 3: board found, post by different author (lines 32-33) ───────────

  Scenario: Post by another author cannot be deleted
    Given the dpost board lookup will return a board
    And the dpost board has a post by "SomeoneElse"
    When the dpost delete post command is invoked
    Then the dpost player should see "You can only delete your own posts."

  # ── Branch 4: board found, post by player (lines 34-36) ─────────────────────

  Scenario: Player deletes their own post
    Given the dpost board lookup will return a board
    And the dpost board has a post by the current player
    When the dpost delete post command is invoked
    Then the dpost player should see "Deleted post #7"
    And the dpost board should have deleted post 7
