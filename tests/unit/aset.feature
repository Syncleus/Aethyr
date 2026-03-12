Feature: AsetCommand action
  In order to let admins modify game-object attributes at runtime
  As a maintainer of the Aethyr engine
  I want AsetCommand#action to correctly dispatch attribute changes.

  Background:
    Given a stubbed AsetCommand environment

  # --- "here" shortcut (line 17-18) into named-attribute path ----------------
  Scenario: Setting smell on "here" appends a period and stores value
    Given a target object exists for "here"
    And the attribute is "smell"
    And the value is "roses"
    When the AsetCommand action is invoked
    Then the player should see "will now smell like: roses."

  # --- object not found (lines 42-46) ----------------------------------------
  Scenario: Object not found produces an error message
    Given the object reference is "nonexistent_goid"
    And find_object will return nil
    And the attribute is "smell"
    And the value is "roses"
    When the AsetCommand action is invoked
    Then the player should see "Cannot find"

  # --- smell nil (lines 63-65, 70) -------------------------------------------
  Scenario: Clearing smell with nil removes the info entry
    Given a target object exists
    And the attribute is "smell"
    And the value is "nil"
    When the AsetCommand action is invoked
    Then the player should see "will no longer smell"

  # --- smell with value (lines 67-68) ----------------------------------------
  Scenario: Setting smell stores the value
    Given a target object exists
    And the attribute is "smell"
    And the value is "like lavender"
    When the AsetCommand action is invoked
    Then the player should see "will now smell like:"

  # --- feel/texture nil (lines 72-74, 79) ------------------------------------
  Scenario: Clearing texture with nil removes the info entry
    Given a target object exists
    And the attribute is "feel"
    And the value is "nil"
    When the AsetCommand action is invoked
    Then the player should see "will no longer have a particular texture"

  # --- feel/texture with value (lines 76-77) ----------------------------------
  Scenario: Setting texture stores the value
    Given a target object exists
    And the attribute is "texture"
    And the value is "smooth"
    When the AsetCommand action is invoked
    Then the player should see "will now feel like:"

  # --- taste nil (lines 81-83, 88) -------------------------------------------
  Scenario: Clearing taste with nil removes the info entry
    Given a target object exists
    And the attribute is "taste"
    And the value is "nil"
    When the AsetCommand action is invoked
    Then the player should see "will no longer have a particular taste"

  # --- taste with value (lines 85-86) ----------------------------------------
  Scenario: Setting taste stores the value
    Given a target object exists
    And the attribute is "taste"
    And the value is "bitter"
    When the AsetCommand action is invoked
    Then the player should see "will now taste like:"

  # --- sound/listen nil (lines 90-92, 97) ------------------------------------
  Scenario: Clearing sound with nil removes the info entry
    Given a target object exists
    And the attribute is "sound"
    And the value is "nil"
    When the AsetCommand action is invoked
    Then the player should see "will no longer make sounds"

  # --- sound/listen with value (lines 94-95) ----------------------------------
  Scenario: Setting sound stores the value
    Given a target object exists
    And the attribute is "listen"
    And the value is "buzzing"
    When the AsetCommand action is invoked
    Then the player should see "will now sound like:"

  # --- unknown named attribute (lines 99-100) --------------------------------
  Scenario: Unknown non-@ attribute produces an error
    Given a target object exists
    And the attribute is "color"
    And the value is "red"
    When the AsetCommand action is invoked
    Then the player should see "What are you trying to set?"

  # --- value ending with punctuation skips period append (line 57) ------------
  Scenario: Value ending with punctuation is not appended
    Given a target object exists
    And the attribute is "smell"
    And the value is "like roses!"
    When the AsetCommand action is invoked
    Then the player should see "will now smell like: like roses!"

  # --- value "!nothing" resolves to nil (line 53-54) --------------------------
  Scenario: Value !nothing resolves to nil and clears attribute
    Given a target object exists
    And the attribute is "smell"
    And the value is "!nothing"
    When the AsetCommand action is invoked
    Then the player should see "will no longer smell"

  # --- @ attribute not found without force (lines 104-106) -------------------
  Scenario: Instance variable not present without force gives error
    Given a target object exists
    And the attribute is "@nonexistent"
    And the value is "hello"
    When the AsetCommand action is invoked
    Then the player should see "No such setting/variable/attribute"

  # --- @ attribute with Array current value (lines 108-111) ------------------
  Scenario: Setting an @ attribute whose current value is an Array
    Given a target object exists with an array attribute "@tags"
    And the attribute is "@tags"
    And the value is "foo bar"
    When the AsetCommand action is invoked
    Then the player should see "Set"
    And the player should see "attribute @tags"

  # --- @ attribute set to "true" (lines 114-117) -----------------------------
  Scenario: Setting an @ attribute to true
    Given a target object exists with a string attribute "@flag" set to "old"
    And the attribute is "@flag"
    And the value is "true"
    When the AsetCommand action is invoked
    Then the player should see "Set"

  # --- @ attribute set to "false" (lines 118-119) ----------------------------
  Scenario: Setting an @ attribute to false
    Given a target object exists with a string attribute "@flag" set to "old"
    And the attribute is "@flag"
    And the value is "false"
    When the AsetCommand action is invoked
    Then the player should see "Set"

  # --- @ attribute set to a symbol (lines 120-121) ---------------------------
  Scenario: Setting an @ attribute to a symbol
    Given a target object exists with a string attribute "@flag" set to "old"
    And the attribute is "@flag"
    And the value is ":mysym"
    When the AsetCommand action is invoked
    Then the player should see "Set"

  # --- @ attribute set to nil (lines 122-123) --------------------------------
  Scenario: Setting an @ attribute to nil
    Given a target object exists with a string attribute "@flag" set to "old"
    And the attribute is "@flag"
    And the value is "nil"
    When the AsetCommand action is invoked
    Then the player should see "Set"

  # --- @ attribute set to integer (lines 124-125) ----------------------------
  Scenario: Setting a numeric @ attribute to an integer
    Given a target object exists with an integer attribute "@count" set to 5
    And the attribute is "@count"
    And the value is "42"
    When the AsetCommand action is invoked
    Then the player should see "Set"

  # --- @ attribute set to integer when current is String remains string ------
  Scenario: Setting a string @ attribute with a number keeps it as string
    Given a target object exists with a string attribute "@label" set to "abc"
    And the attribute is "@label"
    And the value is "99"
    When the AsetCommand action is invoked
    Then the player should see "Set"

  # --- @ attribute set to "!nothing" (lines 126-127) -------------------------
  Scenario: Setting an @ attribute to !nothing yields empty string
    Given a target object exists with a string attribute "@flag" set to "old"
    And the attribute is "@flag"
    And the value is "!nothing"
    When the AsetCommand action is invoked
    Then the player should see "Set"

  # --- @ attribute set to "!delete" (lines 128-131) --------------------------
  Scenario: Deleting an @ attribute with !delete removes it
    Given a target object exists with a string attribute "@flag" set to "old"
    And the attribute is "@flag"
    And the value is "!delete"
    When the AsetCommand action is invoked
    Then the player should see "Removed attribute"

  # --- @ attribute multi-word value (lines 135-136) --------------------------
  Scenario: Setting an @ attribute to a multi-word string
    Given a target object exists with a string attribute "@desc" set to "old"
    And the attribute is "@desc"
    And the value is "a shiny sword"
    When the AsetCommand action is invoked
    Then the player should see "Set"

  # --- "all" class branch – valid class (lines 19-22, 24, 30, 32-36, 39) ----
  Scenario: Setting attribute on all objects of a class
    Given the object reference is "all String"
    And the attribute is "smell"
    And the value is "nice"
    And the manager has objects of class String
    When the AsetCommand action is invoked
    Then Admin.aset should have been called

  # --- "all" class branch – invalid class (lines 25-27) ----------------------
  Scenario: Setting attribute on all objects of an unknown class
    Given the object reference is "all Xyzzynonexistent"
    And the attribute is "smell"
    And the value is "nice"
    When the AsetCommand action is invoked
    Then the player should see "No such object type"

  # --- @ attribute with force flag (lines 104, 107-108 else branch) ----------
  Scenario: Force-setting a new @ attribute creates it
    Given a target object exists
    And the attribute is "@brand_new"
    And the value is "hello"
    And the force flag is set
    When the AsetCommand action is invoked
    Then the player should see "Set"
