Feature: StatusCommand action
  In order to let players check their current condition
  As a developer of the Aethyr engine
  I want the StatusCommand#action to correctly report health, satiety, and pose.

  Background:
    Given a stubbed StatusCommand environment

  # --- action method: lines 14-16 ---
  Scenario: Displaying status with a pose set
    Given the status player health is "in great shape"
    And the status player satiety is "satisfied"
    And the status player pose is "sitting down"
    When the StatusCommand action is invoked
    Then the status player should see "You are in great shape."
    And the status player should see "You are feeling satisfied."
    And the status player should see "You are currently sitting down."

  Scenario: Displaying status with no pose defaults to standing up
    Given the status player health is "near death"
    And the status player satiety is "starving"
    And the status player pose is nil
    When the StatusCommand action is invoked
    Then the status player should see "You are near death."
    And the status player should see "You are feeling starving."
    And the status player should see "You are currently standing up."

  Scenario: Displaying status with different health and satiety values
    Given the status player health is "feeling fine"
    And the status player satiety is "a bit hungry"
    And the status player pose is "leaning against the wall"
    When the StatusCommand action is invoked
    Then the status player should see "You are feeling fine."
    And the status player should see "You are feeling a bit hungry."
    And the status player should see "You are currently leaning against the wall."
