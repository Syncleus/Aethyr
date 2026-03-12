Feature: AdescCommand action
  In order to let admins change object descriptions at runtime
  As a maintainer of the Aethyr engine
  I want AdescCommand#action to correctly update descriptions on game objects.

  Background:
    Given a stubbed adesc_cmd environment

  # --- constructor (line 9) ---------------------------------------------------
  Scenario: AdescCommand can be instantiated
    Then the adesc_cmd should be instantiated successfully

  # --- object is "here" => uses room (lines 18-19) ----------------------------
  Scenario: Object "here" targets the current room with inroom false
    Given the adesc_cmd object reference is "here"
    And adesc_cmd inroom is false
    And adesc_cmd desc is "A dark cave"
    When the adesc_cmd action is invoked
    Then the adesc_cmd player should see "now looks like:"
    And the adesc_cmd player should see "A dark cave"

  # --- object is not "here" => find_object (line 21) --------------------------
  Scenario: Object is not "here" so find_object is used
    Given the adesc_cmd object reference is "sword"
    And adesc_cmd find_object returns an adesc_cmd object named "Rusty Sword"
    And adesc_cmd inroom is false
    And adesc_cmd desc is "A battered blade"
    When the adesc_cmd action is invoked
    Then the adesc_cmd player should see "Rusty Sword now looks like:"
    And the adesc_cmd player should see "A battered blade"

  # --- object not found => "Cannot find X." (lines 24-26) --------------------
  Scenario: Object not found produces an error message
    Given the adesc_cmd object reference is "ghost"
    And adesc_cmd find_object returns nil
    When the adesc_cmd action is invoked
    Then the adesc_cmd player should see "Cannot find ghost."

  # --- inroom true, desc nil => show_in_look=false (lines 29-32) -------------
  Scenario: Inroom true with nil desc hides object from room description
    Given the adesc_cmd object reference is "here"
    And adesc_cmd inroom is true
    And adesc_cmd desc is nil
    When the adesc_cmd action is invoked
    Then the adesc_cmd room show_in_look should be false
    And the adesc_cmd player should see "will not be shown in the room description."

  # --- inroom true, desc "false" => show_in_look=false (lines 29-32) ---------
  Scenario: Inroom true with desc "false" hides object from room description
    Given the adesc_cmd object reference is "here"
    And adesc_cmd inroom is true
    And adesc_cmd desc is "false"
    When the adesc_cmd action is invoked
    Then the adesc_cmd room show_in_look should be false
    And the adesc_cmd player should see "will not be shown in the room description."

  # --- inroom true, desc has value => show_in_look=desc (lines 34-35) --------
  Scenario: Inroom true with a real desc sets show_in_look to desc
    Given the adesc_cmd object reference is "here"
    And adesc_cmd inroom is true
    And adesc_cmd desc is "A glowing fountain sits in the center."
    When the adesc_cmd action is invoked
    Then the adesc_cmd room show_in_look should be "A glowing fountain sits in the center."
    And the adesc_cmd player should see "The room will show"

  # --- inroom false => set short_desc (lines 38-39) --------------------------
  Scenario: Inroom false sets short_desc via instance_variable_set
    Given the adesc_cmd object reference is "sword"
    And adesc_cmd find_object returns an adesc_cmd object named "Rusty Sword"
    And adesc_cmd inroom is false
    And adesc_cmd desc is "A gleaming blade"
    When the adesc_cmd action is invoked
    Then the adesc_cmd object short_desc should be "A gleaming blade"
    And the adesc_cmd player should see "Rusty Sword now looks like:"
