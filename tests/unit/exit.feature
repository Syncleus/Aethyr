Feature: Exit game object
  An Exit is a game object that connects two rooms. It stores a reference
  to the destination room and provides a peer method to describe what lies
  on the other side.

  # -------------------------------------------------------------------
  # Construction / initialize  (lines 15-20)
  # -------------------------------------------------------------------
  Scenario: Creating an Exit with no arguments sets defaults
    Given I require the Exit library
    When I create a new Exit with no arguments
    Then the exit generic should be "exit"
    And the exit article should be "an"
    And the exit exit_room should be nil

  Scenario: Creating an Exit with an exit_room sets the destination
    Given I require the Exit library
    When I create a new Exit with exit_room "room_42"
    Then the exit exit_room should be "room_42"

  # -------------------------------------------------------------------
  # peer – exit_room is nil  (line 33)
  # -------------------------------------------------------------------
  Scenario: peer returns no-destination message when exit_room is nil
    Given I require the Exit library
    And a new Exit with no exit_room
    When I call peer on the exit
    Then the exit peer result should be "This exit does not seem to lead anywhere."

  # -------------------------------------------------------------------
  # peer – exit_room set but room not found  (lines 25-28)
  # -------------------------------------------------------------------
  Scenario: peer returns darkness message when the destination room is not found
    Given I require the Exit library
    And a new Exit with exit_room "nonexistent_room"
    And the exit manager returns nil for "nonexistent_room"
    When I call peer on the exit
    Then the exit peer result should be "You see only darkness of the deepest black."

  # -------------------------------------------------------------------
  # peer – exit_room set and room found  (lines 25-26, 30)
  # -------------------------------------------------------------------
  Scenario: peer returns room name when the destination room exists
    Given I require the Exit library
    And a new Exit with exit_room "existing_room"
    And the exit manager returns a mock room named "Grand Hall" for "existing_room"
    When I call peer on the exit
    Then the exit peer result should be "Squinting slightly, you can see Grand Hall."
