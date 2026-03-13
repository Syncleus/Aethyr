Feature: DeletePlayerCommand action
  In order to let admins remove player accounts from the game
  As a maintainer of the Aethyr engine
  I want DeletePlayerCommand#action to handle all deletion scenarios correctly.

  Background:
    Given a stubbed DeletePlayerCommand environment

  # --- Player does not exist (lines 18-20) -----------------------------------
  Scenario: Target player does not exist
    Given the delplr manager reports player "ghostplayer" does not exist
    When the DeletePlayerCommand action is invoked for "ghostplayer"
    Then the delplr player should see "No such player found: ghostplayer"

  # --- Player is currently logged in (lines 21-23) ---------------------------
  Scenario: Target player is currently logged in
    Given the delplr manager reports player "activeplayer" exists
    And the delplr manager reports player "activeplayer" is logged in
    When the DeletePlayerCommand action is invoked for "activeplayer"
    Then the delplr player should see "Player is currently logged in. Deletion aborted."

  # --- Name matches own name (lines 24-26) -----------------------------------
  Scenario: Admin tries to delete themselves
    Given the delplr manager reports player "adminplayer" exists
    And the delplr manager reports player "adminplayer" is not logged in
    When the DeletePlayerCommand action is invoked for "adminplayer"
    Then the delplr player should see "You cannot delete yourself this way. Use DELETE ME PLEASE instead."

  # --- Successful delete but player still exists (lines 29, 31-32) -----------
  Scenario: Deletion fails silently and player still exists
    Given the delplr manager reports player "badplayer" exists
    And the delplr manager reports player "badplayer" is not logged in
    And the delplr manager will fail to fully delete "badplayer"
    When the DeletePlayerCommand action is invoked for "badplayer"
    Then the delplr player should see "Something went wrong. Player still exists."

  # --- Successful delete, player is gone (lines 29, 34) ----------------------
  Scenario: Successful deletion removes the player
    Given the delplr manager reports player "oldplayer" exists
    And the delplr manager reports player "oldplayer" is not logged in
    And the delplr manager will successfully delete "oldplayer"
    When the DeletePlayerCommand action is invoked for "oldplayer"
    Then the delplr player should see "oldplayer deleted."
