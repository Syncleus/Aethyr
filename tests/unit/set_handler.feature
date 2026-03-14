Feature: SetHandler input parsing
  In order to ensure the SetHandler correctly routes player input to the right command
  As a maintainer of the Aethyr engine
  I want the SetHandler player_input method to parse set commands and dispatch the correct actions.

  Background:
    Given a stubbed SetHandler input environment

  # --- "set color on" branch (lines 57-59) ------------------------------------
  Scenario: "set color on" submits a SetcolorCommand with option "on"
    When the set handler input is "set color on"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a SetcolorCommand
    And the submitted set handler action should have option "on"
    And the submitted set handler action should not have color

  Scenario: "set color off" submits a SetcolorCommand with option "off"
    When the set handler input is "set color off"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a SetcolorCommand
    And the submitted set handler action should have option "off"

  Scenario: "set color default" submits a SetcolorCommand with option "default"
    When the set handler input is "set color default"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a SetcolorCommand
    And the submitted set handler action should have option "default"

  Scenario: "set colors on" (plural) also submits a SetcolorCommand
    When the set handler input is "set colors on"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a SetcolorCommand
    And the submitted set handler action should have option "on"

  Scenario: "SET COLOR OFF" (uppercase) submits a SetcolorCommand
    When the set handler input is "SET COLOR OFF"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a SetcolorCommand
    And the submitted set handler action should have option "OFF"

  # --- "set color" / "set colors" catchall branch (lines 60-61) ---------------
  Scenario: "set color" with no arguments submits a ShowcolorsCommand
    When the set handler input is "set color"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a ShowcolorsCommand

  Scenario: "set colors" with no arguments submits a ShowcolorsCommand
    When the set handler input is "set colors"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a ShowcolorsCommand

  Scenario: "set color prompt red" submits a ShowcolorsCommand due to regex ordering
    When the set handler input is "set color prompt red"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a ShowcolorsCommand

  # --- "set password" branch (lines 66-67) ------------------------------------
  Scenario: "set password" submits a SetpasswordCommand
    When the set handler input is "set password"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a SetpasswordCommand

  Scenario: "SET PASSWORD" (uppercase) submits a SetpasswordCommand
    When the set handler input is "SET PASSWORD"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a SetpasswordCommand

  # --- "set <setting> <value>" generic branch (lines 68-71) -------------------
  Scenario: "set wordwrap 80" submits a SetCommand with setting and value
    When the set handler input is "set wordwrap 80"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a SetCommand
    And the submitted set handler action should have setting "wordwrap"
    And the submitted set handler action should have value "80"

  Scenario: "set layout full" submits a SetCommand with setting and value
    When the set handler input is "set layout full"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a SetCommand
    And the submitted set handler action should have setting "layout"
    And the submitted set handler action should have value "full"

  Scenario: "set pagelength 50" submits a SetCommand with setting and value
    When the set handler input is "set pagelength 50"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a SetCommand
    And the submitted set handler action should have setting "pagelength"
    And the submitted set handler action should have value "50"

  Scenario: "set wordwrap" with no value submits a SetCommand with empty value
    When the set handler input is "set wordwrap"
    Then the set handler should have submitted 1 action
    And the submitted set handler action should be a SetCommand
    And the submitted set handler action should have setting "wordwrap"
    And the submitted set handler action should have value ""

  # --- Non-matching input (no action submitted) --------------------------------
  Scenario: Non-matching input does not submit any action
    When the set handler input is "look around"
    Then the set handler should have submitted 0 actions

  Scenario: Empty-ish input does not submit any action
    When the set handler input is "hello"
    Then the set handler should have submitted 0 actions
