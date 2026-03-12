Feature: AreactionCommand action
  In order to let admins manage reactions on game objects
  As a maintainer of the Aethyr engine
  I want AreactionCommand#action to correctly handle all reaction sub-commands.

  Background:
    Given a stubbed AreactionCommand environment

  # --- "reload" + "all" branch (lines 18-25) --------------------------------
  Scenario: Reload all reacting objects
    Given the areaction command is "reload"
    And the areaction object is "all"
    When the AreactionCommand action is invoked
    Then the areaction player should see "Updated reactions for"

  # --- "all ClassName" with valid class (lines 26-28, 30, 36, 38-43) ---------
  Scenario: Apply areaction to all objects of a valid class
    Given the areaction command is "show"
    And the areaction object is "all String"
    When the AreactionCommand action is invoked
    Then Admin.areaction should have been called

  # --- "all ClassName" with lowercase class name that gets capitalized --------
  Scenario: Apply areaction to all objects of a lowercase class name
    Given the areaction command is "show"
    And the areaction object is "all string"
    When the AreactionCommand action is invoked
    Then Admin.areaction should have been called

  # --- "all ClassName" with invalid class (lines 26-28, 30-33) ---------------
  Scenario: Apply areaction to all objects of an invalid class
    Given the areaction command is "show"
    And the areaction object is "all Xyzzynonexistent"
    When the AreactionCommand action is invoked
    Then the areaction player should see "No such object type."

  # --- object == "here" (lines 46-47) ----------------------------------------
  Scenario: Using "here" resolves to the room object
    Given the areaction command is "show"
    And the areaction object is "here"
    And the areaction room supports show_reactions
    When the AreactionCommand action is invoked
    Then the areaction player should see "reactions listed"

  # --- object not found via find_object (lines 49, 52-54) --------------------
  Scenario: Object not found produces an error
    Given the areaction command is "show"
    And the areaction object is "nonexistent_thing"
    And areaction find_object will return nil
    When the AreactionCommand action is invoked
    Then the areaction player should see "Cannot find:"

  # --- object not Reacts with "load" command (lines 55-57) -------------------
  Scenario: Non-reacting object with load command gets Reacts extended
    Given the areaction command is "load"
    And the areaction object is "some_object"
    And a areaction target object exists without Reacts
    And the areaction file is "testfile"
    And the reaction file "testfile" exists
    When the AreactionCommand action is invoked
    Then the areaction player should see "Object cannot react, adding react ability."

  # --- object not Reacts with "reload" command (lines 55-57) -----------------
  Scenario: Non-reacting object with reload command gets Reacts extended
    Given the areaction command is "reload"
    And the areaction object is "some_object"
    And a areaction target object exists without Reacts
    When the AreactionCommand action is invoked
    Then the areaction player should see "Object cannot react, adding react ability."

  # --- "add" command, action added successfully (lines 60, 62-63) ------------
  Scenario: Add a new action to an object
    Given the areaction command is "add"
    And the areaction object is "some_object"
    And a areaction target object exists with add returning true
    And the areaction action_name is "wave"
    When the AreactionCommand action is invoked
    Then the areaction player should see "Added wave"

  # --- "add" command, action already exists (lines 62, 65) -------------------
  Scenario: Add an action that already exists
    Given the areaction command is "add"
    And the areaction object is "some_object"
    And a areaction target object exists with add returning false
    And the areaction action_name is "wave"
    When the AreactionCommand action is invoked
    Then the areaction player should see "Already had a reaction by that name."

  # --- "delete" command, action removed (lines 68-69) ------------------------
  Scenario: Delete an action from an object
    Given the areaction command is "delete"
    And the areaction object is "some_object"
    And a areaction target object exists with delete returning true
    And the areaction action_name is "wave"
    When the AreactionCommand action is invoked
    Then the areaction player should see "Removed wave"

  # --- "delete" command, action not found (lines 68, 71) ---------------------
  Scenario: Delete an action that does not exist
    Given the areaction command is "delete"
    And the areaction object is "some_object"
    And a areaction target object exists with delete returning false
    And the areaction action_name is "wave"
    When the AreactionCommand action is invoked
    Then the areaction player should see "That verb was not associated with this object."

  # --- "load" command, file does not exist (lines 74-76) ---------------------
  Scenario: Load reactions from a non-existent file
    Given the areaction command is "load"
    And the areaction object is "some_object"
    And a areaction target object exists that is Reacts
    And the areaction file is "missing_file"
    And the reaction file "missing_file" does not exist
    When the AreactionCommand action is invoked
    Then the areaction player should see "No such reaction file - missing_file"

  # --- "load" command, file exists (lines 74, 79-80) -------------------------
  Scenario: Load reactions from an existing file
    Given the areaction command is "load"
    And the areaction object is "some_object"
    And a areaction target object exists that is Reacts
    And the areaction file is "good_file"
    And the reaction file "good_file" exists
    When the AreactionCommand action is invoked
    Then the areaction player should see "Probably loaded reactions."

  # --- "reload" command on specific object (lines 82-83) ---------------------
  Scenario: Reload reactions on a specific object
    Given the areaction command is "reload"
    And the areaction object is "some_object"
    And a areaction target object exists that is Reacts
    When the AreactionCommand action is invoked
    Then the areaction player should see "Probably reloaded reactions."

  # --- "clear" command (lines 85-86) -----------------------------------------
  Scenario: Clear reactions on an object
    Given the areaction command is "clear"
    And the areaction object is "some_object"
    And a areaction target object exists that is Reacts
    When the AreactionCommand action is invoked
    Then the areaction player should see "Probably cleared out reactions."

  # --- "show" command with custom actions (lines 88-89) ----------------------
  Scenario: Show reactions on an object with custom actions
    Given the areaction command is "show"
    And the areaction object is "some_object"
    And a areaction target object exists with custom actions
    When the AreactionCommand action is invoked
    Then the areaction player should see "Custom actions:"

  # --- "show" command with show_reactions (lines 92-93) ----------------------
  Scenario: Show reactions on an object that can show_reactions
    Given the areaction command is "show"
    And the areaction object is "some_object"
    And the areaction target object supports show_reactions
    When the AreactionCommand action is invoked
    Then the areaction player should see "reactions listed"

  # --- "show" command without show_reactions (lines 92, 95) ------------------
  Scenario: Show reactions on an object that cannot show_reactions
    Given the areaction command is "show"
    And the areaction object is "some_object"
    And a areaction target object exists without show_reactions
    When the AreactionCommand action is invoked
    Then the areaction player should see "Object does not react."

  # --- "show" with empty actions but can show_reactions (lines 88, 92-93) ----
  Scenario: Show reactions on object with empty actions but can show_reactions
    Given the areaction command is "show"
    And the areaction object is "some_object"
    And a areaction target object exists with empty actions and show_reactions
    When the AreactionCommand action is invoked
    Then the areaction player should see "reactions listed"

  # --- unknown command / default case (lines 97-102) -------------------------
  Scenario: Unknown command shows usage options
    Given the areaction command is "foobar"
    And the areaction object is "some_object"
    And a areaction target object exists that is Reacts
    When the AreactionCommand action is invoked
    Then the areaction player should see "Options:"
    And the areaction player should see "areaction load <object> <file>"
    And the areaction player should see "areaction reload <object> <file>"
    And the areaction player should see "areaction [add|delete] <object> <action>"
    And the areaction player should see "areaction [clear|show] <object>"
