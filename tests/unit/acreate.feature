Feature: AcreateCommand action
  In order to let admins create game objects at runtime
  As a maintainer of the Aethyr engine
  I want AcreateCommand#action to correctly create objects or reject invalid input.

  Background:
    Given a stubbed AcreateCommand environment

  # --- initialize (line 9) + valid object creation (lines 15-17, 19, 21-22, 33-37, 39, 41-44, 47-48)
  Scenario: Creating a valid GameObject subclass with a room present
    Given the acreate object is "acreatetestitem"
    And the acreate name is "Shiny Sword"
    And the acreate alt_names are "sword,blade"
    And the acreate generic is "weapon"
    And the acreate args are "test_arg"
    When the AcreateCommand action is invoked
    Then the acreate player should see "Created:"
    And the acreate room should have received an out_event
    And the acreate event to_player should contain "Frowning in concentration"
    And the acreate event to_other should contain "Frowning in concentration"

  # --- valid creation without optional vars (lines 33-37 partial)
  Scenario: Creating a valid object without optional name/alt_names/generic
    Given the acreate object is "acreatetestitem"
    When the AcreateCommand action is invoked
    Then the acreate player should see "Created:"

  # --- undefined class (lines 21, 24-25)
  Scenario: Attempting to create a nonexistent class
    Given the acreate object is "totallynotarealclass"
    When the AcreateCommand action is invoked
    Then the acreate player should see "No such thing. Sorry."

  # --- class is not a subclass of GameObject (lines 28-30)
  Scenario: Attempting to create from a non-GameObject class
    Given the acreate object is "string"
    When the AcreateCommand action is invoked
    Then the acreate player should see "You cannot create a"

  # --- class is Player (lines 28-30)
  Scenario: Attempting to create a Player
    Given the acreate object is "player"
    When the AcreateCommand action is invoked
    Then the acreate player should see "You cannot create a"

  # --- room is nil (line 41 false branch, still hits 47-48)
  Scenario: Creating an object when room is nil
    Given the acreate object is "acreatetestitem"
    And the acreate room is nil
    When the AcreateCommand action is invoked
    Then the acreate player should see "Created:"
    And the acreate room should not have received an out_event
