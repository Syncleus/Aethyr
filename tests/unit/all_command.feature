Feature: AllCommand action
  In order to let players view all posts on an in-game bulletin board
  As a developer of the Aethyr engine
  I want the AllCommand to correctly handle all branches.

  Background:
    Given a stubbed AllCommand environment

  # --- constructor (line 9) ---------------------------------------------------
  Scenario: AllCommand can be instantiated
    Then the AllCommand should be instantiated successfully

  # --- no board found (lines 15-17, 19-21) ------------------------------------
  Scenario: No board in the room outputs an error
    Given the all board lookup will return nil
    When the all command action is invoked
    Then the all player should see "There do not seem to be any postings here."

  # --- board found, player has word_wrap set (lines 15-17, 19, 24, 26) --------
  Scenario: Board found and player has custom word_wrap
    Given the all board lookup will return a board
    And the all player word_wrap is set to 80
    When the all command action is invoked
    Then the all player should see the board listing

  # --- board found, player word_wrap is nil (lines 15-17, 19, 24, 26) ---------
  Scenario: Board found and player word_wrap is nil uses default
    Given the all board lookup will return a board
    And the all player word_wrap is nil
    When the all command action is invoked
    Then the all player should see the board listing
