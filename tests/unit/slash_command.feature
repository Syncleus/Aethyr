Feature: SlashCommand action
  In order to let players slash at enemies with a weapon
  As a maintainer of the Aethyr engine
  I want SlashCommand#action to correctly handle all slash scenarios.

  Background:
    Given a stubbed SlashCommand environment

  # --- Combat not ready (lines 15-16, 18) ---
  Scenario: Combat not ready causes early return
    Given slash combat is not ready
    When the SlashCommand action is invoked
    Then the slash player should have no output

  # --- No weapon available (lines 15-16, 18-pass, 20-23) ---
  Scenario: No slash weapon outputs cannot slash message
    Given slash combat is ready
    And the slash player has no slash weapon
    When the SlashCommand action is invoked
    Then the slash player should see "You are not wielding a weapon you can slash with."

  # --- No target found at all (lines 15-16, 18-pass, 20-pass, 26, 28-30) ---
  Scenario: No target outputs who are you trying to attack
    Given slash combat is ready
    And the slash player has a slash weapon
    And there is no slash target
    And the slash player has no last_target
    When the SlashCommand action is invoked
    Then the slash player should see "Who are you trying to attack?"

  # --- Target found but Combat.valid_target? returns false (lines 26, 28-else, 32) ---
  Scenario: Invalid target causes early return from valid_target check
    Given slash combat is ready
    And the slash player has a slash weapon
    And the slash target is "goblin"
    And slash combat valid_target returns false
    When the SlashCommand action is invoked
    Then the slash player should not see "Who are you trying to attack?"

  # --- Full successful slash with explicit target (lines 35, 37, 39-43, 45-47, 49, 51-55, 57) ---
  Scenario: Successful slash with explicit target completes full combat action
    Given slash combat is ready
    And the slash player has a slash weapon called "broadsword"
    And the slash target is "goblin"
    And slash combat valid_target returns true
    When the SlashCommand action is invoked
    Then the slash player last_target should be set to the target goid
    And the slash command to_other should contain "broadsword"
    And the slash command to_target should contain "broadsword"
    And the slash command to_player should contain "broadsword"
    And the slash command action should be :weapon_hit
    And the slash command combat_action should be :slash
    And the slash command blockable should be true
    And the slash player balance should be false
    And the slash player should be in combat
    And the slash target should be in combat
    And the slash room should have received out_event
    And slash combat should have received future_event

  # --- Successful slash falling back to last_target (line 26 alternate branch) ---
  Scenario: Slash with no explicit target falls back to last_target
    Given slash combat is ready
    And the slash player has a slash weapon called "scimitar"
    And there is no slash target
    And the slash player last_target is "goblin"
    And slash combat valid_target returns true
    When the SlashCommand action is invoked
    Then the slash player last_target should be set to the target goid
    And the slash command to_player should contain "scimitar"
    And the slash command action should be :weapon_hit
    And the slash player balance should be false
    And the slash room should have received out_event
    And slash combat should have received future_event
