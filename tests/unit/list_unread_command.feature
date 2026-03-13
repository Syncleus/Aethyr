Feature: ListUnreadCommand action
  In order to let players list unread posts from in-game bulletin boards
  As a developer of the Aethyr engine
  I want the ListUnreadCommand to correctly handle all listing branches.

  Background:
    Given a stubbed ListUnreadCommand environment

  # ── Branch 1: no board found (lines 19-21) ──────────────────────────────────

  Scenario: No board in the room outputs an error
    Given the lunread board lookup will return nil
    When the lunread list unread command is invoked
    Then the lunread player should see "There do not seem to be any postings here."

  # ── Branch 2: board found, player.info.boards is nil (lines 24-25, 28) ─────

  Scenario: Listing unread posts when player boards hash is nil
    Given the lunread board lookup will return a board
    And the lunread player info boards is nil
    When the lunread list unread command is invoked
    Then the lunread player info boards should be initialized
    And the lunread player should see the unread listing

  # ── Branch 3: board found, player.info.boards already exists (line 28) ──────

  Scenario: Listing unread posts when player boards hash already exists
    Given the lunread board lookup will return a board
    And the lunread player info boards already exists
    When the lunread list unread command is invoked
    And the lunread player should see the unread listing
