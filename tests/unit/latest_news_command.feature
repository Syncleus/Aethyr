Feature: LatestNewsCommand action
  In order to let players view the latest news from in-game bulletin boards
  As a developer of the Aethyr engine
  I want the LatestNewsCommand to correctly handle all branches.

  Background:
    Given a stubbed LatestNewsCommand environment

  # ── Branch 1: no board found (lines 19-21) ──────────────────────────────────

  Scenario: No board in the room outputs an error
    Given the lnews board lookup will return nil
    When the lnews latest news command is invoked
    Then the lnews player should see "There do not seem to be any postings here."

  # ── Branch 2: board found, not a Newsboard (lines 24-25, 28-30, 32) ────────

  Scenario: Board found that is not a Newsboard logs and lists latest
    Given the lnews board lookup will return a non-newsboard board
    And the lnews command has offset 2 and limit 10
    When the lnews latest news command is invoked
    Then the lnews player should see the board listing
    And the lnews board should have received list_latest with wordwrap 100 offset 2 limit 10

  # ── Branch 3: board found, is a Newsboard (lines 24, 28-30, 32) ────────────

  Scenario: Board found that is a Newsboard skips log and lists latest
    Given the lnews board lookup will return a newsboard
    And the lnews player has word_wrap 80 and page_height 25
    When the lnews latest news command is invoked
    Then the lnews player should see the board listing
    And the lnews board should have received list_latest with wordwrap 80 offset 0 limit 25

  # ── Branch 4: defaults when offset/limit not set and word_wrap is nil ───────

  Scenario: Defaults are used when offset and limit are not set
    Given the lnews board lookup will return a newsboard
    And the lnews player has no word_wrap and page_height 15
    When the lnews latest news command is invoked with no offset or limit
    Then the lnews player should see the board listing
    And the lnews board should have received list_latest with wordwrap 100 offset 0 limit 15
