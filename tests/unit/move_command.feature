Feature: MoveCommand action
  In order to let players navigate between rooms
  As a maintainer of the Aethyr engine
  I want MoveCommand#action to correctly handle movement in all cases.

  Background:
    Given a stubbed MoveCommand environment

  # --- initialize (line 9) + exit is nil (lines 13-14, 16-18) ----------------
  Scenario: Moving in a direction with no exit
    Given the move direction is "north"
    And the room has no exit for "north"
    When the MoveCommand action is invoked
    Then the move player should see "You cannot go north."

  # --- exit is closed (lines 13-14, 19-21) -----------------------------------
  Scenario: Moving toward a closed exit
    Given the move direction is "east"
    And the room has a closed exit for "east"
    When the MoveCommand action is invoked
    Then the move player should see "That exit is closed. Perhaps you should open it?"

  # --- new_room is nil (lines 13-14, 24, 26-28) ------------------------------
  Scenario: Exit leads to a nonexistent room
    Given the move direction is "south"
    And the room has an open exit for "south" named "dark passage" leading to "void_room_id"
    And the manager cannot find room "void_room_id"
    When the MoveCommand action is invoked
    Then the move player should see "That exit dark passage leads into the void."

  # --- successful move (lines 13-14, 24, 31-41) ------------------------------
  Scenario: Successfully moving to another room
    Given the move direction is "west"
    And the room has an open exit for "west" named "wooden door" leading to "new_room_goid"
    And the manager can find room "new_room_goid"
    When the MoveCommand action is invoked
    Then the move player should see "A nice room"
    And the move player container should be "new_room_goid"
    And the move old room should have received out_event
    And the move old room should have removed the player
    And the move new room should have added the player
