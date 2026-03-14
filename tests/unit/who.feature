Feature: WhoCommand action
  In order to let players see who is currently online
  As a maintainer of the Aethyr engine
  I want WhoCommand#action to list all visiting players with their rooms.

  Background:
    Given a stubbed WhoCommand environment

  # --- Multiple players online with rooms (lines 14-18, 21) ------------------
  Scenario: Multiple players online with rooms
    Given the who manager find_all returns players "Bob, Alice" in rooms "Town Square, Forest"
    When the WhoCommand action is invoked
    Then the who player output should contain "The following people are visiting Aethyr:"
    And the who player output should contain "Alice - Forest"
    And the who player output should contain "Bob - Town Square"

  # --- No players online (lines 14-16, 21) -----------------------------------
  Scenario: No players online
    Given the who manager find_all returns no players
    When the WhoCommand action is invoked
    Then the who player output should contain "The following people are visiting Aethyr:"
    And the who player output should have 1 entry

  # --- Player with nil room (lines 14-18, 21) --------------------------------
  Scenario: Player whose room is nil
    Given the who manager find_all returns player "Ghost" with no room
    When the WhoCommand action is invoked
    Then the who player output should contain "Ghost - "
