Feature: Door game object
  A Door is an Exit that includes the Openable trait.  It can optionally be
  connected to another Door so that opening or closing one side automatically
  notifies the other.

  # -------------------------------------------------------------------
  # Construction / initialize  (lines 13, 15-19)
  # -------------------------------------------------------------------
  Scenario: Creating a Door with default arguments
    Given I require the Door library
    When I create a new Door with default arguments
    Then the door generic should be "door"
    And the door article should be "a"
    And the door should not be connected
    And the door should be lockable
    And the door keys should be empty
    And the door should be a kind of Exit

  Scenario: Creating a Door with lockable false
    Given I require the Door library
    When I create a new Door with lockable false
    Then the door should not be lockable

  # -------------------------------------------------------------------
  # connected?  (line 25)
  # -------------------------------------------------------------------
  Scenario: A new door is not connected
    Given I require the Door library
    And a new Door
    Then the door should not be connected

  Scenario: A door with connected_to set is connected
    Given I require the Door library
    And a new Door with connected_to set to "other_door_id"
    Then the door should be connected

  # -------------------------------------------------------------------
  # other_side_opened  (lines 30-32)
  # -------------------------------------------------------------------
  Scenario: other_side_opened sets open to true and outputs message
    Given I require the Door library
    And a new Door that is closed
    And the door container is set to "room_123"
    And the manager returns a mock room for "room_123"
    When I call other_side_opened on the door
    Then the door should be open
    And the mock room should have received output "The door opens."

  # -------------------------------------------------------------------
  # other_side_closed  (lines 37-39)
  # -------------------------------------------------------------------
  Scenario: other_side_closed sets open to false and outputs message
    Given I require the Door library
    And a new Door that is open
    And the door container is set to "room_123"
    And the manager returns a mock room for "room_123"
    When I call other_side_closed on the door
    Then the door should be closed
    And the mock room should have received output "The door closes."

  # -------------------------------------------------------------------
  # open with connected_to, state changes  (lines 44, 46-47, 50-52)
  # -------------------------------------------------------------------
  Scenario: Opening a connected door notifies the other side
    Given I require the Door library
    And a new Door that is closed and not locked
    And the door is connected to another door "other_door_goid"
    And the manager is set up for open with connected door
    When I call open on the door with a mock event
    Then the door should be open
    And the other side door should have received other_side_opened

  # -------------------------------------------------------------------
  # open with connected_to, state unchanged (locked)
  # -------------------------------------------------------------------
  Scenario: Opening a locked connected door does not notify the other side
    Given I require the Door library
    And a new Door that is closed and locked
    And the door is connected to another door "other_door_goid"
    And the manager is set up for open with connected door
    When I call open on the door with a mock event
    Then the door should be closed
    And the other side door should not have received other_side_opened

  # -------------------------------------------------------------------
  # open without connected_to  (line 55)
  # -------------------------------------------------------------------
  Scenario: Opening a door without connected_to just calls super
    Given I require the Door library
    And a new Door that is closed and not locked
    And the manager is set up for open without connected door
    When I call open on the door with a mock event
    Then the door should be open

  # -------------------------------------------------------------------
  # close with connected_to, state changes  (lines 61, 63-64, 67-69)
  # -------------------------------------------------------------------
  Scenario: Closing a connected door notifies the other side
    Given I require the Door library
    And a new Door that is open
    And the door is connected to another door "other_door_goid"
    And the manager is set up for close with connected door
    When I call close on the door with a mock event
    Then the door should be closed
    And the other side door should have received other_side_closed

  # -------------------------------------------------------------------
  # close without connected_to  (line 72)
  # -------------------------------------------------------------------
  Scenario: Closing a door without connected_to just calls super
    Given I require the Door library
    And a new Door that is open
    And the manager is set up for close without connected door
    When I call close on the door with a mock event
    Then the door should be closed

  # -------------------------------------------------------------------
  # connect_to with Door object  (lines 81-85, 87)
  # -------------------------------------------------------------------
  Scenario: connect_to with a Door object sets connected_to and connects back
    Given I require the Door library
    And two new Doors
    When I connect door A to door B
    Then door A connected_to should be door B game_object_id
    And door B should be connected

  Scenario: connect_to with a closed Door syncs open state to closed
    Given I require the Door library
    And two new Doors that are both closed
    When I connect door A to door B
    Then door A should be closed

  Scenario: connect_to with an open Door syncs open state via recursion
    Given I require the Door library
    And two new Doors where both are open
    When I connect door A to door B
    Then door A should be open

  # -------------------------------------------------------------------
  # connect_to with non-Door  (line 90)
  # -------------------------------------------------------------------
  Scenario: connect_to with a string just sets connected_to
    Given I require the Door library
    And a new Door
    When I connect the door to string "some_goid_value"
    Then the door connected_to should be "some_goid_value"
