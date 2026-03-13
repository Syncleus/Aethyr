Feature: WritePostCommand action
  In order to let players write posts to in-game bulletin boards
  As a developer of the Aethyr engine
  I want the WritePostCommand to correctly handle all posting branches.

  Background:
    Given a stubbed WritePostCommand environment

  # ── Branch 1: no board found (lines 19-21) ─────────────────────────────────

  Scenario: No board in the room outputs an error
    Given the wpost board lookup will return nil
    When the wpost write post command is invoked
    Then the wpost player should see "There do not seem to be any postings here."
    And the wpost board should not have received a save

  # ── Branch 2: board found, post written, no announcement (lines 24, 26-30) ─

  Scenario: Writing a post without board announcement
    Given the wpost board lookup will return a board without announcement
    And the wpost player will enter subject "My Subject" and message "Hello world"
    When the wpost write post command is invoked
    Then the wpost player should see "What is the subject of this post?"
    And the wpost player should see "You have written post #1."
    And the wpost board should have saved a post from the player with subject "My Subject" and message "Hello world"
    And the wpost area should not have received output

  # ── Branch 3: board found, post written, with announcement (lines 24, 26-34)

  Scenario: Writing a post with board announcement
    Given the wpost board lookup will return a board with announcement "New post on the board!"
    And the wpost player will enter subject "Announce Test" and message "Important news"
    When the wpost write post command is invoked
    Then the wpost player should see "What is the subject of this post?"
    Then the wpost player should see "You have written post #1."
    And the wpost board should have saved a post from the player with subject "Announce Test" and message "Important news"
    And the wpost area should have received output "New post on the board!"

  # ── Branch 4: board found, editor cancelled (message nil) (lines 26-28) ────

  Scenario: Cancelling the editor does not save a post
    Given the wpost board lookup will return a board without announcement
    And the wpost player will enter subject "Cancelled" and cancel the editor
    When the wpost write post command is invoked
    Then the wpost player should see "What is the subject of this post?"
    And the wpost board should not have received a save

  # ── Branch 2 with reply_to set ─────────────────────────────────────────────

  Scenario: Writing a reply post passes reply_to to save_post
    Given the wpost board lookup will return a board without announcement
    And the wpost player will enter subject "Re: Original" and message "My reply"
    And the wpost command will have reply_to set to 5
    When the wpost write post command is invoked
    Then the wpost player should see "You have written post #1."
    And the wpost board should have saved a post with reply_to 5
