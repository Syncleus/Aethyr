Feature: AinfoCommand action
  In order to let admins inspect and modify game-object info at runtime
  As a maintainer of the Aethyr engine
  I want AinfoCommand#action to correctly dispatch info operations.

  Background:
    Given a stubbed AinfoCommand environment

  # --- initialize (line 9) + basic "set" with "true" (lines 15-17, 44, 51-56, 69-70) ---
  Scenario: Set a value to true on a target object
    Given an ainfo target object exists
    And the ainfo object reference is the target goid
    And the ainfo command is "set"
    And the ainfo attrib is "active"
    And the ainfo value is "true"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "Set active to true"

  # --- "set" with "false" (lines 57-58) ---
  Scenario: Set a value to false on a target object
    Given an ainfo target object exists
    And the ainfo object reference is the target goid
    And the ainfo command is "set"
    And the ainfo attrib is "active"
    And the ainfo value is "false"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "Set active to false"

  # --- "set" with symbol value (lines 59-60) ---
  Scenario: Set a value to a symbol on a target object
    Given an ainfo target object exists
    And the ainfo object reference is the target goid
    And the ainfo command is "set"
    And the ainfo attrib is "kind"
    And the ainfo value is ":weapon"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "Set kind to weapon"

  # --- "set" with nil value (lines 61-62) ---
  Scenario: Set a value to nil on a target object
    Given an ainfo target object exists
    And the ainfo object reference is the target goid
    And the ainfo command is "set"
    And the ainfo attrib is "kind"
    And the ainfo value is "nil"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "Set kind to"

  # --- "set" with integer value (lines 63-64) ---
  Scenario: Set a value to an integer on a target object
    Given an ainfo target object exists
    And the ainfo object reference is the target goid
    And the ainfo command is "set"
    And the ainfo attrib is "level"
    And the ainfo value is "42"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "Set level to 42"

  # --- "set" with !nothing value (lines 65-66) ---
  Scenario: Set a value to empty string via !nothing on a target object
    Given an ainfo target object exists
    And the ainfo object reference is the target goid
    And the ainfo command is "set"
    And the ainfo attrib is "desc"
    And the ainfo value is "!nothing"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "Set desc to"

  # --- "set" with multi-word value (line 54 else branch, 69-70) ---
  Scenario: Set a multi-word value on a target object
    Given an ainfo target object exists
    And the ainfo object reference is the target goid
    And the ainfo command is "set"
    And the ainfo attrib is "desc"
    And the ainfo value is "a shiny sword"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "Set desc to a shiny sword"

  # --- "delete" command (lines 72-73) ---
  Scenario: Delete an attribute from a target object
    Given an ainfo target object exists with info attribute "kind" set to "sword"
    And the ainfo object reference is the target goid
    And the ainfo command is "delete"
    And the ainfo attrib is "kind"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "Deleted kind from"

  # --- "show" command (line 75) ---
  Scenario: Show info for a target object
    Given an ainfo target object exists
    And the ainfo object reference is the target goid
    And the ainfo command is "show"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "Info:"

  # --- "clear" command (lines 77-78) ---
  Scenario: Clear info for a target object
    Given an ainfo target object exists
    And the ainfo object reference is the target goid
    And the ainfo command is "clear"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "Completely cleared info for"

  # --- else/unknown command (line 80) ---
  Scenario: Unknown command produces error message
    Given an ainfo target object exists
    And the ainfo object reference is the target goid
    And the ainfo command is "bogus"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "Huh? What?"

  # --- "here" shortcut (lines 17-18) ---
  Scenario: Object reference here resolves to player container
    Given an ainfo target object exists for "here"
    And the ainfo command is "show"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "Info:"

  # --- "me" shortcut (lines 19-20) ---
  Scenario: Object reference me resolves to player object
    Given an ainfo target object exists for "me"
    And the ainfo command is "show"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "Info:"

  # --- "all" branch with valid class (lines 21-24, 26, 32, 34-36, 38, 41) ---
  Scenario: Iterating over all objects of a valid class
    Given the ainfo object reference is "all String"
    And the ainfo command is "show"
    When the AinfoCommand action is invoked
    Then Admin.ainfo should have been called

  # --- "all" branch with already capitalized class (line 24 unless) ---
  Scenario: Iterating over all objects with already capitalized class
    Given the ainfo object reference is "all String"
    And the ainfo command is "show"
    When the AinfoCommand action is invoked
    Then Admin.ainfo should have been called

  # --- "all" branch with lowercase class that needs capitalizing (line 24) ---
  Scenario: Iterating over all objects with lowercase class name
    Given the ainfo object reference is "all string"
    And the ainfo command is "show"
    When the AinfoCommand action is invoked
    Then Admin.ainfo should have been called

  # --- "all" branch with invalid class (lines 26-29) ---
  Scenario: Iterating over all objects of an invalid class
    Given the ainfo object reference is "all Xyzzynonexistent"
    And the ainfo command is "show"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "No such object type."

  # --- object not found (lines 44, 46-48) ---
  Scenario: Object not found produces error message
    Given the ainfo object reference is "nonexistent_goid"
    And ainfo find_object will return nil
    And the ainfo command is "show"
    When the AinfoCommand action is invoked
    Then the ainfo player should see "What object?"
