Feature: AcdoorCommand action
  In order to let admins create doors between rooms
  As a maintainer of the Aethyr engine
  I want AcdoorCommand#action to correctly create door pairs and handle edge cases.

  # --------------------------------------------------------------------------
  # exit_room provided and found – lines 9, 14-16, 34, 42-44, 46-47, 49-52
  # --------------------------------------------------------------------------
  Scenario: Creating a door when exit_room is explicitly provided and found
    Given a stubbed AcdoorCommand environment
    And the acdoor exit_room is set to a valid room
    And the acdoor direction is "north"
    When the AcdoorCommand action is invoked
    Then the acdoor player should see "Created:"
    And the acdoor room should have received out_event

  # --------------------------------------------------------------------------
  # exit_room provided but NOT found – lines 14-16, 34, 37-39
  # --------------------------------------------------------------------------
  Scenario: Creating a door when exit_room is provided but not found
    Given a stubbed AcdoorCommand environment
    And the acdoor exit_room is set to an unknown room
    And the acdoor direction is "east"
    When the AcdoorCommand action is invoked
    Then the acdoor player should see "Cannot find"

  # --------------------------------------------------------------------------
  # exit_room nil, direction finds an Exit, other_side found
  # – lines 14-21, 23-25, 30-31, 42-44, 46-47, 49-52
  # --------------------------------------------------------------------------
  Scenario: Replacing an existing exit with a door when other side exists
    Given a stubbed AcdoorCommand environment
    And the acdoor exit_room is nil
    And the acdoor direction is "west"
    And an existing exit in direction "west" with other side
    When the AcdoorCommand action is invoked
    Then the acdoor player should see "Removed opposite exit"
    And the acdoor player should see "Removed exit"
    And the acdoor player should see "Created:"
    And the acdoor room should have received out_event

  # --------------------------------------------------------------------------
  # exit_room nil, direction finds an Exit, other_side NOT found
  # – lines 14-21, 27, 30-31, 42-44, 46-47, 49-52
  # --------------------------------------------------------------------------
  Scenario: Replacing an existing exit with a door when other side does not exist
    Given a stubbed AcdoorCommand environment
    And the acdoor exit_room is nil
    And the acdoor direction is "south"
    And an existing exit in direction "south" without other side
    When the AcdoorCommand action is invoked
    Then the acdoor player should see "Could not find opposite exit"
    And the acdoor player should see "Removed exit"
    And the acdoor player should see "Created:"

  # --------------------------------------------------------------------------
  # exit_room nil, direction does NOT find an Exit – lines 14-18, 37-39
  # --------------------------------------------------------------------------
  Scenario: No exit found and no exit_room given produces error
    Given a stubbed AcdoorCommand environment
    And the acdoor exit_room is nil
    And the acdoor direction is "up"
    And no existing exit in that direction
    When the AcdoorCommand action is invoked
    Then the acdoor player should see "Cannot find"
