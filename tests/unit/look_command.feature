Feature: LookCommand action
  In order to let players observe their surroundings and examine objects
  As a maintainer of the Aethyr engine
  I want LookCommand#action to correctly handle all look scenarios.

  Background:
    Given a stubbed LookCommand environment

  # --- Default look: room exists (lines 14, 16-17, 68-70) --------------------
  Scenario: Looking with no arguments shows the room description
    When the LookCommand action is invoked with no arguments
    Then the look player should see "A nice room"

  # --- Default look: room is nil (lines 14, 16-17, 72) -----------------------
  Scenario: Looking when room is nil shows nothing to look at
    Given the look room is nil
    When the LookCommand action is invoked with no arguments
    Then the look player should see "Nothing to look at."

  # --- Blind: cannot look, no reason (lines 19-21) ---------------------------
  Scenario: Looking while blind with no reason says cannot see
    Given the player is blind with no reason
    When the LookCommand action is invoked with no arguments
    Then the look player should see "You cannot see."

  # --- Blind: cannot look, with reason (line 23) -----------------------------
  Scenario: Looking while blind with a reason raises error due to blind_data bug
    Given the player is blind with reason "Your eyes are closed"
    When the LookCommand action is invoked expecting error
    Then the look command should have raised an error

  # --- Look at: object not found (lines 26-28, 30-32) ------------------------
  Scenario: Looking at an object that does not exist
    When the LookCommand action is invoked with at "unicorn"
    Then the look player should see "Look at what, again?"

  # --- Look at "here": Exit object (lines 26-28, 35-36) ----------------------
  Scenario: Looking at an exit object shows its peer description
    Given a look target exit with peer text "You see the Great Hall."
    When the LookCommand action is invoked with at "north"
    Then the look player should see "You see the Great Hall."

  # --- Look at "here": Room with indoors terrain (lines 26-27, 37-40) --------
  Scenario: Looking at here when room is indoors
    Given the look room is indoors
    When the LookCommand action is invoked with at "here"
    Then the look player should see "You are indoors."

  Scenario: Looking at here when room is underwater
    Given the look room is underwater
    When the LookCommand action is invoked with at "here"
    Then the look player should see "You are underwater."

  Scenario: Looking at here when room is water
    Given the look room is water
    When the LookCommand action is invoked with at "here"
    Then the look player should see "You are swimming."

  # --- Look at "here": Room with area (lines 42-44) --------------------------
  Scenario: Looking at here with a room area and terrain type
    Given the look room has an area "Emerald Forest" with terrain type
    When the LookCommand action is invoked with at "here"
    Then the look player should see "You are in a place called TestRoom"
    And the look player should see "Emerald Forest"
    And the look player should see "The area is generally"

  # --- Look at "here": Room without area but with room_type (lines 42, 43-false, 45-46) --
  Scenario: Looking at here with no area but with room_type
    Given the look room has no area but has room_type
    When the LookCommand action is invoked with at "here"
    Then the look player should see "Where you are standing is considered to be"

  # --- Look at "here": Room without area and no room_type (lines 42, 43-false, 45-false, 48) --
  Scenario: Looking at here with no area and no room_type
    Given the look room has no area and no room_type
    When the LookCommand action is invoked with at "here"
    Then the look player should see "You are unsure about anything else"

  # --- Look at self (lines 26-28, 50-52) --------------------------------------
  Scenario: Looking at yourself shows your description and inventory
    When the LookCommand action is invoked looking at self
    Then the look player should see "You look over yourself"
    And the look player should see "inventory contents"

  # --- Look at other object (lines 26-28, 54) --------------------------------
  Scenario: Looking at a generic object shows its long description
    Given a look target object "sword" with long desc "A gleaming sword."
    When the LookCommand action is invoked with at "sword"
    Then the look player should see "A gleaming sword."

  # --- Look in: object not found (lines 56-58, 60-61) ------------------------
  Scenario: Looking inside something that does not exist
    When the LookCommand action is invoked with in "phantom"
    Then the look player should see "Look inside what?"

  # --- Look in: cannot look inside (lines 56-58, 60-false, 62-63) ------------
  Scenario: Looking inside something that cannot be looked inside
    Given a look in target "chest" that cannot be looked inside
    When the LookCommand action is invoked with in "chest"
    Then the look player should see "You cannot look inside that."

  # --- Look in: success (lines 56-58, 60-false, 62-false, 65) ----------------
  Scenario: Looking inside a container successfully
    Given a look in target "chest" that can be looked inside
    When the LookCommand action is invoked with in "chest"
    Then the look in target should have received look_inside

  # --- describe_area: Room with terrain_type (lines 80-82, 87) ----------------
  Scenario: describe_area with Room that has terrain_type
    Given the look room has an area "Forest" with terrain type
    And the look room has a terrain type with room_text "a forest clearing"
    When the LookCommand action is invoked with at "here"
    Then the look player should see "a forest clearing"

  # --- describe_area: Room without terrain_type (lines 80-82, 87) -------------
  Scenario: describe_area with Room that has nil terrain_type
    Given the look room has an area "Forest" with terrain type
    And the look room has nil terrain type
    When the LookCommand action is invoked with at "here"
    Then the look player should see "uncertain"

  # --- describe_area: Area with terrain_type (lines 83-85, 87) ----------------
  Scenario: describe_area with Area that has terrain_type
    Given the look room has an area "Forest" with area terrain type "waving grasslands"
    When the LookCommand action is invoked with at "here"
    Then the look player should see "waving grasslands"

  # --- describe_area: Area without terrain_type (lines 83-85, 87) -------------
  Scenario: describe_area with Area that has nil terrain_type
    Given the look room has an area "Forest" with nil area terrain type
    And the look room has nil terrain type
    When the LookCommand action is invoked with at "here"
    Then the look player should see "uncertain"
