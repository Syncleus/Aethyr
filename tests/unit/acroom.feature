Feature: AcroomCommand action
  In order to let admins create new rooms connected to the current room
  As a maintainer of the Aethyr engine
  I want AcroomCommand#action to correctly create rooms and exits.

  # --------------------------------------------------------------------------
  # No area (room.container is nil) – lines 15-17, 57-63, 97-98
  # --------------------------------------------------------------------------
  Scenario: Creating a room with no area creates the room and exits
    Given a stubbed AcroomCommand environment with no area
    And the acroom out direction is "north"
    And the acroom in direction is "south"
    And the acroom new room name is "New Chamber"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Created:"
    And the acroom room should see "flash of light"

  # --------------------------------------------------------------------------
  # Area with map_type :none – line 22 condition false, same path as no area
  # --------------------------------------------------------------------------
  Scenario: Creating a room with area map_type none skips map logic
    Given a stubbed AcroomCommand environment with area map_type none
    And the acroom out direction is "east"
    And the acroom in direction is "west"
    And the acroom new room name is "Dark Hall"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Created:"
    And the acroom room should see "flash of light"

  # --------------------------------------------------------------------------
  # Mappable area (:rooms) direction north – lines 22-25, 27, 49, 57-63, 97-98
  # --------------------------------------------------------------------------
  Scenario: Creating a room north in a rooms-type area
    Given a stubbed AcroomCommand environment with area map_type rooms
    And the acroom out direction is "north"
    And the acroom in direction is "south"
    And the acroom new room name is "North Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Created:"
    And the acroom player should see "@ 0x1"
    And the acroom room should see "flash of light"

  # --------------------------------------------------------------------------
  # Mappable area direction south – line 29
  # --------------------------------------------------------------------------
  Scenario: Creating a room south in a mappable area
    Given a stubbed AcroomCommand environment with area map_type rooms
    And the acroom out direction is "south"
    And the acroom in direction is "north"
    And the acroom new room name is "South Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Created:"
    And the acroom player should see "@ 0x-1"

  # --------------------------------------------------------------------------
  # Mappable area direction west – line 31
  # --------------------------------------------------------------------------
  Scenario: Creating a room west in a mappable area
    Given a stubbed AcroomCommand environment with area map_type rooms
    And the acroom out direction is "west"
    And the acroom in direction is "east"
    And the acroom new room name is "West Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Created:"
    And the acroom player should see "@ -1x0"

  # --------------------------------------------------------------------------
  # Mappable area direction east – line 33
  # --------------------------------------------------------------------------
  Scenario: Creating a room east in a mappable area
    Given a stubbed AcroomCommand environment with area map_type rooms
    And the acroom out direction is "east"
    And the acroom in direction is "west"
    And the acroom new room name is "East Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Created:"
    And the acroom player should see "@ 1x0"

  # --------------------------------------------------------------------------
  # Diagonal directions in mappable area – lines 35-36, 38-39, 41-42, 44-45
  # --------------------------------------------------------------------------
  Scenario: Creating a room northeast in a mappable area is rejected
    Given a stubbed AcroomCommand environment with area map_type rooms
    And the acroom out direction is "northeast"
    And the acroom in direction is "southwest"
    And the acroom new room name is "NE Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Can not create a northeast exit in a mappable area"

  Scenario: Creating a room northwest in a mappable area is rejected
    Given a stubbed AcroomCommand environment with area map_type rooms
    And the acroom out direction is "northwest"
    And the acroom in direction is "southeast"
    And the acroom new room name is "NW Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Can not create a northwest exit in a mappable area"

  Scenario: Creating a room southeast in a mappable area is rejected
    Given a stubbed AcroomCommand environment with area map_type rooms
    And the acroom out direction is "southeast"
    And the acroom in direction is "northwest"
    And the acroom new room name is "SE Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Can not create a southeast exit in a mappable area"

  Scenario: Creating a room southwest in a mappable area is rejected
    Given a stubbed AcroomCommand environment with area map_type rooms
    And the acroom out direction is "southwest"
    And the acroom in direction is "northeast"
    And the acroom new room name is "SW Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Can not create a southwest exit in a mappable area"

  # --------------------------------------------------------------------------
  # Non-cardinal direction (else) in mappable area – line 47, new_pos = nil
  # --------------------------------------------------------------------------
  Scenario: Creating a room with non-cardinal direction in a mappable area sets new_pos to nil
    Given a stubbed AcroomCommand environment with area map_type rooms
    And the acroom out direction is "up"
    And the acroom in direction is "down"
    And the acroom new room name is "Upper Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Created:"
    And the acroom player should not see "@ "

  # --------------------------------------------------------------------------
  # Position collision – lines 52-54
  # --------------------------------------------------------------------------
  Scenario: Creating a room at an occupied position is rejected
    Given a stubbed AcroomCommand environment with area map_type rooms and position collision
    And the acroom out direction is "north"
    And the acroom in direction is "south"
    And the acroom new room name is "Blocked Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "There is already a room at the coordinates"

  # --------------------------------------------------------------------------
  # World map with west neighbor – lines 65-75
  # --------------------------------------------------------------------------
  Scenario: Creating a room in a world map area with a west neighbor
    Given a stubbed AcroomCommand environment with world map and west neighbor
    And the acroom out direction is "north"
    And the acroom in direction is "south"
    And the acroom new room name is "World Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Created:"
    And the acroom created objects count should be at least 5

  # --------------------------------------------------------------------------
  # World map with east neighbor (no west) – lines 65, 76-81
  # --------------------------------------------------------------------------
  Scenario: Creating a room in a world map area with an east neighbor
    Given a stubbed AcroomCommand environment with world map and east neighbor
    And the acroom out direction is "north"
    And the acroom in direction is "south"
    And the acroom new room name is "World Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Created:"
    And the acroom created objects count should be at least 5

  # --------------------------------------------------------------------------
  # World map with north neighbor (no west/east) – lines 65, 82-87
  # --------------------------------------------------------------------------
  Scenario: Creating a room in a world map area with a north neighbor
    Given a stubbed AcroomCommand environment with world map and north neighbor
    And the acroom out direction is "east"
    And the acroom in direction is "west"
    And the acroom new room name is "World Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Created:"
    And the acroom created objects count should be at least 5

  # --------------------------------------------------------------------------
  # World map with south neighbor (no west/east/north) – lines 65, 88-93
  # --------------------------------------------------------------------------
  Scenario: Creating a room in a world map area with a south neighbor
    Given a stubbed AcroomCommand environment with world map and south neighbor
    And the acroom out direction is "east"
    And the acroom in direction is "west"
    And the acroom new room name is "World Room"
    When the AcroomCommand action is invoked
    Then the acroom player should see "Created:"
    And the acroom created objects count should be at least 5
