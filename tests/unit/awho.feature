Feature: AwhoCommand action
  In order to let admins see who is currently online
  As a maintainer of the Aethyr engine
  I want AwhoCommand#action to list all online players.

  Background:
    Given a stubbed AwhoCommand environment

  # --- Single player online (lines 15-17, 19-21, 24-25) ----------------------
  Scenario: One player online
    Given the awho manager find_all returns one player named "Alice"
    When the AwhoCommand action is invoked
    Then the awho player should see "Players currently online:"
    And the awho player should see "Alice"

  # --- Multiple players online (lines 15-17, 19-21, 24-25) -------------------
  Scenario: Multiple players online
    Given the awho manager find_all returns players named "Alice, Bob, Carol"
    When the AwhoCommand action is invoked
    Then the awho player should see "Players currently online:"
    And the awho player should see "Alice, Bob, Carol"

  # --- No players online (lines 15-17, 19, 24-25) ----------------------------
  Scenario: No players online
    Given the awho manager find_all returns no players
    When the AwhoCommand action is invoked
    Then the awho player should see "Players currently online:"
    And the awho player should see ""
