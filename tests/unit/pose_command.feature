Feature: PoseCommand action
  In order to let players set or clear a visible pose
  As a maintainer of the Aethyr engine
  I want PoseCommand#action to correctly handle all pose scenarios.

  Background:
    Given a stubbed PoseCommand environment

  # --- pose set to "none" clears the pose (lines 17-19) ----------------------
  Scenario: Pose "none" clears the player pose
    Given the pose player has pose "sitting cross-legged"
    When the PoseCommand action is invoked with pose "none"
    Then the pose player pose should be nil
    And the pose player should see "You are no longer posing."

  # --- pose set to "None" mixed case also clears (lines 17-19) ---------------
  Scenario: Pose "None" mixed case also clears the player pose
    Given the pose player has pose "leaning on a wall"
    When the PoseCommand action is invoked with pose "None"
    Then the pose player pose should be nil
    And the pose player should see "You are no longer posing."

  # --- pose set to "NONE" all caps also clears (lines 17-19) -----------------
  Scenario: Pose "NONE" all caps also clears the player pose
    Given the pose player has pose "meditating"
    When the PoseCommand action is invoked with pose "NONE"
    Then the pose player pose should be nil
    And the pose player should see "You are no longer posing."

  # --- custom pose sets the pose (lines 21-22) --------------------------------
  Scenario: Custom pose sets the player pose
    When the PoseCommand action is invoked with pose "sitting cross-legged"
    Then the pose player pose should be "sitting cross-legged"
    And the pose player should see "Your pose is now: sitting cross-legged."

  # --- another custom pose (lines 21-22) --------------------------------------
  Scenario: Another custom pose sets the player pose
    When the PoseCommand action is invoked with pose "leaning against the wall"
    Then the pose player pose should be "leaning against the wall"
    And the pose player should see "Your pose is now: leaning against the wall."
