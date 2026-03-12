Feature: AwatchCommand action
  In order to let admins observe mobile output in real-time
  As a maintainer of the Aethyr engine
  I want AwatchCommand#action to correctly start/stop watching mobiles.

  Background:
    Given a stubbed AwatchCommand environment

  # --- initialize (line 9) + nil target (lines 15-20) -------------------------
  Scenario: Nil target prompts user
    Given the awatch target is nil
    When the AwatchCommand action is invoked
    Then the awatch player should see "What mobile do you want to watch?"

  # --- non-Mobile target (lines 15-17, 21-23) ---------------------------------
  Scenario: Non-mobile target is rejected
    Given the awatch target is a non-mobile object
    When the AwatchCommand action is invoked
    Then the awatch player should see "You can only use this to watch mobiles."

  # --- "start" + already watching (lines 26, 28-29) ---------------------------
  Scenario: Start watching when already watching
    Given the awatch target is a mobile named "Goblin"
    And the awatch mobile is already redirecting to the player
    And the awatch command is "start"
    When the AwatchCommand action is invoked
    Then the awatch player should see "You are already watching Goblin."

  # --- "start" + not yet watching (lines 26, 28, 31-33) -----------------------
  Scenario: Start watching a mobile
    Given the awatch target is a mobile named "Goblin"
    And the awatch mobile is not redirecting to the player
    And the awatch command is "start"
    When the AwatchCommand action is invoked
    Then the awatch player should see "Watching Goblin."
    And the awatch mobile should see "TestWatcher is watching you."
    And the awatch mobile redirect should be set to the player

  # --- "stop" + not watching (lines 35-37) ------------------------------------
  Scenario: Stop watching when not watching
    Given the awatch target is a mobile named "Goblin"
    And the awatch mobile is not redirecting to the player
    And the awatch command is "stop"
    When the AwatchCommand action is invoked
    Then the awatch player should see "You are not watching Goblin."

  # --- "stop" + watching (lines 35-36, 39-40) ---------------------------------
  Scenario: Stop watching a mobile
    Given the awatch target is a mobile named "Goblin"
    And the awatch mobile is already redirecting to the player
    And the awatch command is "stop"
    When the AwatchCommand action is invoked
    Then the awatch player should see "No longer watching Goblin."
    And the awatch mobile redirect should be nil

  # --- else (toggle) + not watching (lines 42-46) -----------------------------
  Scenario: Toggle starts watching when not watching
    Given the awatch target is a mobile named "Goblin"
    And the awatch mobile is not redirecting to the player
    And the awatch command is "toggle"
    When the AwatchCommand action is invoked
    Then the awatch player should see "Watching Goblin."
    And the awatch mobile should see "TestWatcher is watching you."
    And the awatch mobile redirect should be set to the player

  # --- else (toggle) + already watching (lines 42-43, 47-49) ------------------
  Scenario: Toggle stops watching when already watching
    Given the awatch target is a mobile named "Goblin"
    And the awatch mobile is already redirecting to the player
    And the awatch command is "toggle"
    When the AwatchCommand action is invoked
    Then the awatch player should see "No longer watching Goblin."
    And the awatch mobile redirect should be nil
