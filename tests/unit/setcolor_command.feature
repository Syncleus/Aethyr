Feature: SetcolorCommand action
  In order to let players customize their color preferences
  As a maintainer of the Aethyr engine
  I want SetcolorCommand#action to correctly handle color toggling, resetting, and custom color changes.

  Background:
    Given a stubbed SetcolorCommand environment

  # --- option "off" (lines 17-19) ---------------------------------------------
  Scenario: Option off disables colors
    Given the scolor option is "off"
    When the SetcolorCommand action is invoked
    Then the scolor player io use_color should be false
    And the scolor player should see "Colors disabled."

  # --- option "on" (lines 20-22) ----------------------------------------------
  Scenario: Option on enables colors
    Given the scolor option is "on"
    When the SetcolorCommand action is invoked
    Then the scolor player io use_color should be true
    And the scolor player should see "Colors enabled."

  # --- option "default" (lines 23-25) -----------------------------------------
  Scenario: Option default resets colors to defaults
    Given the scolor option is "default"
    When the SetcolorCommand action is invoked
    Then the scolor player io to_default should have been called
    And the scolor player should see "Colors set to defaults."

  # --- custom option (line 27) ------------------------------------------------
  Scenario: Custom option calls set_color with option and color
    Given the scolor option is "prompt"
    And the scolor color is "red"
    When the SetcolorCommand action is invoked
    Then the scolor player io set_color should have been called with "prompt" and "red"
    And the scolor player should see "Color for prompt set to red."
