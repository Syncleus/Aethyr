Feature: Room game object
  A Room is a Container that holds players, mobiles, exits, and things.
  It provides methods for looking around, listing occupants, and navigating.

  Background:
    Given a stubbed Room test environment

  # --- initialize -----------------------------------------------------------
  Scenario: Room initializes with correct defaults
    When I create a new Room for room tests
    Then the room generic should be "room"

  # --- indoors? -------------------------------------------------------------
  Scenario: indoors? returns the terrain indoors flag
    When I create a new Room for room tests
    And I set the room indoors flag to true
    Then the room should be indoors

  # --- add (non-player, non-mobile) -----------------------------------------
  Scenario: Adding a regular object to the room
    When I create a new Room for room tests
    And I add a regular object to the room
    Then the room inventory should contain that object

  # --- add (player) ---------------------------------------------------------
  Scenario: Adding a player to the room
    When I create a new Room for room tests
    And I add a room-test player to the room
    Then the room inventory should contain that player

  # --- add (mobile) ---------------------------------------------------------
  Scenario: Adding a mobile to the room
    When I create a new Room for room tests
    And I add a room-test mobile to the room
    Then the room inventory should contain that mobile

  # --- exit(direction) ------------------------------------------------------
  Scenario: exit returns an exit in the given direction
    When I create a new Room for room tests
    And I add an exit going "north" to the room
    Then the room exit "north" should return the exit

  # --- players method -------------------------------------------------------
  Scenario: players returns visible player objects excluding specified
    When I create a new Room for room tests
    And I populate the room with players and non-players
    Then the room players list should contain only visible players

  Scenario: players with only_visible false returns all players
    When I create a new Room for room tests
    And I populate the room with visible and invisible players
    Then the room players list with only_visible false should include invisible players

  # --- mobiles method -------------------------------------------------------
  Scenario: mobiles returns alive non-player creatures
    When I create a new Room for room tests
    And I populate the room with mobiles and players
    Then the room mobiles list should contain only visible alive mobiles

  # --- things method --------------------------------------------------------
  Scenario: things returns non-exit non-alive items
    When I create a new Room for room tests
    And I populate the room with things and exits
    Then the room things list should contain only non-exit non-alive items

  # --- exits (second definition, line 85) -----------------------------------
  Scenario: exits returns only exit objects
    When I create a new Room for room tests
    And I populate the room with exits and non-exits
    Then the room exits list should contain only exits

  # --- look (blind player) --------------------------------------------------
  Scenario: look returns blind message when player is blind
    When I create a new Room for room tests
    And I set up a blind player for look
    Then the room look should say cannot see while blind

  # --- look (empty room) ---------------------------------------------------
  Scenario: look in an empty room shows basic room info
    When I create a new Room for room tests with name "Empty Hall" and desc "A bare room."
    And I set up room terrain and flags
    And I set up a sighted player for look
    Then the room look should contain "Empty Hall"
    And the room look should contain "A bare room."
    And the room look should contain "Exits: none"

  # --- look (full room with players, exits, mobs, things) ------------------
  Scenario: look in a populated room shows all categories
    When I create a new Room for room tests with name "Grand Hall" and desc "A magnificent hall."
    And I set up room terrain and flags
    And I populate the room inventory for full look test
    And I set up a sighted player for look
    Then the room look should contain "Grand Hall"
    And the room look should contain "A magnificent hall."
    And the room look should contain "player is"
    And the room look should contain "mob is"
    And the room look should contain "items in the room"

  # --- look with show_in_look items ----------------------------------------
  Scenario: look includes show_in_look text in description
    When I create a new Room for room tests with name "Study" and desc "A quiet study."
    And I set up room terrain and flags
    And I add an item with show_in_look text "A painting hangs on the wall."
    And I set up a sighted player for look
    Then the room look should contain "A painting hangs on the wall."

  # --- look with player who has pose ----------------------------------------
  Scenario: look shows player pose when present
    When I create a new Room for room tests with name "Lobby" and desc "A lobby."
    And I set up room terrain and flags
    And I add a player with pose "is sitting" to room inventory
    And I set up a sighted player for look
    Then the room look should contain "is sitting"

  # --- look with player without pose ----------------------------------------
  Scenario: look shows player without pose
    When I create a new Room for room tests with name "Lobby" and desc "A lobby."
    And I set up room terrain and flags
    And I add a player without pose to room inventory
    And I set up a sighted player for look
    Then the room look should contain "<player>"

  # --- look with closed exit -----------------------------------------------
  Scenario: look shows closed exit
    When I create a new Room for room tests with name "Gate" and desc "A gate room."
    And I set up room terrain and flags
    And I add a closed exit "east" to room inventory
    And I set up a sighted player for look
    Then the room look should contain "east"
    And the room look should contain "(closed)"

  # --- look with open exit -------------------------------------------------
  Scenario: look shows open exit
    When I create a new Room for room tests with name "Gate" and desc "A gate room."
    And I set up room terrain and flags
    And I add an open exit "west" to room inventory
    And I set up a sighted player for look
    Then the room look should contain "west"
    And the room look should contain "(open)"

  # --- look with simple exit (no open/close) --------------------------------
  Scenario: look shows simple exit
    When I create a new Room for room tests with name "Hall" and desc "A hallway."
    And I set up room terrain and flags
    And I add a simple exit "south" to room inventory
    And I set up a sighted player for look
    Then the room look should contain "south"

  # --- look with mob -------------------------------------------------------
  Scenario: look shows alive mob
    When I create a new Room for room tests with name "Cave" and desc "A dark cave."
    And I set up room terrain and flags
    And I add an alive mob "Goblin" to room inventory
    And I set up a sighted player for look
    Then the room look should contain "Goblin"
    And the room look should contain "mob is"

  # --- look with thing that has a pose -------------------------------------
  Scenario: look shows thing with pose
    When I create a new Room for room tests with name "Room" and desc "A room."
    And I set up room terrain and flags
    And I add a thing with pose "leaning against the wall" to room inventory
    And I set up a sighted player for look
    Then the room look should contain "leaning against the wall"

  # --- look with thing without pose ----------------------------------------
  Scenario: look shows thing without pose
    When I create a new Room for room tests with name "Room" and desc "A room."
    And I set up room terrain and flags
    And I add a plain thing "Old Sword" to room inventory
    And I set up a sighted player for look
    Then the room look should contain "Old Sword"

  # --- look with thing quantity > 1 ----------------------------------------
  Scenario: look shows thing with quantity
    When I create a new Room for room tests with name "Room" and desc "A room."
    And I set up room terrain and flags
    And I add a thing with quantity 5 to room inventory
    And I set up a sighted player for look
    Then the room look should contain "items in the room"

  # --- look with flags that player can see ----------------------------------
  Scenario: look shows visible flags
    When I create a new Room for room tests with name "Enchanted" and desc "Magical place."
    And I set up room terrain and flags with a visible flag
    And I set up a sighted player for look
    Then the room look should contain "Glowing aura surrounds you"

  # --- look exits sorting ---------------------------------------------------
  Scenario: look sorts exits when present
    When I create a new Room for room tests with name "Cross" and desc "A crossroads."
    And I set up room terrain and flags
    And I add a simple exit "south" to room inventory
    And I add a simple exit "north" to room inventory
    And I set up a sighted player for look
    Then the room look should contain "north"
    And the room look should contain "south"

  # --- look with multiple players -------------------------------------------
  Scenario: look shows plural players text for multiple
    When I create a new Room for room tests with name "Arena" and desc "An arena."
    And I set up room terrain and flags
    And I add a player with pose "is standing" to room inventory
    And I add another player without pose to room inventory
    And I set up a sighted player for look
    Then the room look should contain "players are"

  # --- look with multiple mobs ---------------------------------------------
  Scenario: look shows plural mobs text for multiple
    When I create a new Room for room tests with name "Forest" and desc "A forest."
    And I set up room terrain and flags
    And I add an alive mob "Wolf" to room inventory
    And I add an alive mob "Bear" to room inventory
    And I set up a sighted player for look
    Then the room look should contain "mobs are"

  # --- show_players with players -------------------------------------------
  Scenario: show_players returns player info when players are present
    When I create a new Room for room tests
    And I add a player with pose "is resting" to room inventory
    And I set up a sighted player for look
    Then show_players should return text containing the player name

  # --- show_players with no other players -----------------------------------
  Scenario: show_players returns nil when no other players
    When I create a new Room for room tests
    And I set up a sighted player for look
    Then show_players should return nil
