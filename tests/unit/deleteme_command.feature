Feature: DeletemeCommand action
  In order to allow players to permanently delete their own characters
  As a maintainer of the Aethyr engine
  I want DeletemeCommand#action to handle all deletion branches.

  Background:
    Given a stubbed delme environment

  # --- password provided and correct (lines 14-18) ---------------------------
  Scenario: Correct password deletes the player
    Given the delme password is "correctpass"
    And the delme password check will succeed
    When the delme action is invoked
    Then the delme player should see "will no longer exist"
    And the delme player quit should have been called
    And the delme manager delete_player should have been called

  # --- password provided but incorrect (lines 14, 19-20) ---------------------
  Scenario: Incorrect password keeps the player
    Given the delme password is "wrongpass"
    And the delme password check will fail
    When the delme action is invoked
    Then the delme player should see "You are allowed to continue existing."
    And the delme player quit should not have been called
    And the delme manager delete_player should not have been called

  # --- no password: interactive prompt path (lines 22-29) --------------------
  Scenario: No password prompts and sets up expect callback
    Given the delme has no password
    And the delme expect input is "laterpass"
    And the delme password check will succeed
    When the delme action is invoked
    Then the delme player should see "To confirm your deletion, please enter your password:"
    And the delme io echo_off should have been called
    And the delme io echo_on should have been called
    And the delme generic deleteme should have been called
