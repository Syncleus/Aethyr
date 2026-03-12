Feature: SetpasswordCommand action
  In order to allow players to change their passwords securely
  As a maintainer of the Aethyr engine
  I want SetpasswordCommand#action to handle all password change branches.

  Background:
    Given a stubbed setpwd environment

  # --- new_password provided but fails regex (lines 17-20) --------------------
  Scenario: Direct password change with too-short password
    Given the setpwd new_password is "abc"
    When the setpwd action is invoked
    Then the setpwd player should see "Please only use letters and numbers"

  Scenario: Direct password change with special characters
    Given the setpwd new_password is "p@ss!word"
    When the setpwd action is invoked
    Then the setpwd player should see "Please only use letters and numbers"

  Scenario: Direct password change with too-long password
    Given the setpwd new_password is "aaaaabbbbbcccccddddde"
    When the setpwd action is invoked
    Then the setpwd player should see "Please only use letters and numbers"

  # --- new_password provided and valid (lines 22-23) --------------------------
  Scenario: Direct password change with valid password
    Given the setpwd new_password is "validpass1"
    When the setpwd action is invoked
    Then the setpwd player should see "Your password has been changed."
    And the setpwd manager set_password should have been called

  Scenario: Direct password change with exactly 6 characters
    Given the setpwd new_password is "abcdef"
    When the setpwd action is invoked
    Then the setpwd player should see "Your password has been changed."

  Scenario: Direct password change with exactly 20 characters
    Given the setpwd new_password is "abcdefghij1234567890"
    When the setpwd action is invoked
    Then the setpwd player should see "Your password has been changed."

  # --- interactive flow: wrong old password (lines 26-28, 38-39) --------------
  Scenario: Interactive flow with incorrect old password
    Given the setpwd has no new_password
    And the setpwd old password check will fail
    And the setpwd expect passwords are "wrongpass"
    When the setpwd action is invoked
    Then the setpwd player should see "Please enter your current password:"
    And the setpwd player should see "Sorry, that password is invalid."
    And the setpwd io echo_on should have been called

  # --- interactive flow: correct old password (lines 26-35) -------------------
  Scenario: Interactive flow with correct old password
    Given the setpwd has no new_password
    And the setpwd old password check will succeed
    And the setpwd expect passwords are "correctold,mynewpass1"
    When the setpwd action is invoked
    Then the setpwd player should see "Please enter your current password:"
    And the setpwd player should see "Please enter your new password:"
    And the setpwd settings setpassword should have been called
    And the setpwd io echo_on should have been called
