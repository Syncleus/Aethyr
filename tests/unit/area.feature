Feature: Area game object
  An Area is a GridContainer that holds rooms and provides map rendering.

  Scenario: Area initializes with correct defaults
    Given I have a stub manager for area tests
    And I create a new Area
    Then the area article should be "an"
    And the area generic should be "area"
    And the area map_type should be rooms

  Scenario: render_map with map_type :none
    Given I have a stub manager for area tests
    And I create a new Area
    And the area map_type is set to none
    When I call render_map on the area
    Then the render_map result should contain "defies the laws of physics"

  Scenario: render_map with invalid map_type raises
    Given I have a stub manager for area tests
    And I create a new Area
    And the area map_type is set to invalid
    Then calling render_map should raise an error

  Scenario: render_map with map_type :world delegates to render_world
    Given I have a stub manager for area tests
    And I create a new Area with rooms for world map
    And the area map_type is set to world
    When I call render_map on the area with small grid
    Then the render_map result should be a non-empty string

  Scenario: render_world shows player marker and terrain
    Given I have a stub manager for area tests
    And I create a new Area with a grid of rooms for world map
    When I render the world map centered on the player
    Then the world map should contain the player marker
    And the world map should contain terrain markers

  Scenario: render_world shows spaces for nil rooms
    Given I have a stub manager for area tests
    And I create a new Area with sparse rooms for world map
    When I render the world map centered on the player
    Then the world map should contain spaces for empty positions

  Scenario: render_map with map_type :rooms delegates to render_rooms
    Given I have a stub manager for area tests
    And I create a new Area with rooms for room map
    When I call render_map on the area with small grid
    Then the render_map result should be a non-empty string

  Scenario: render_rooms returns message when position is nil
    Given I have a stub manager for area tests
    And I create a new Area with rooms for room map
    When I call render_rooms with nil position
    Then the result should say location does not appear on maps

  Scenario: render_rooms draws single room with borders
    Given I have a stub manager for area tests
    And I create an Area with a single room at origin
    When I render rooms map centered at origin
    Then the rooms map should contain border characters

  Scenario: render_rooms draws adjacent rooms with crossings
    Given I have a stub manager for area tests
    And I create an Area with a 2x2 grid of connected rooms
    When I render rooms map for the 2x2 grid
    Then the rooms map should contain crossing characters

  Scenario: render_rooms draws north-south exits
    Given I have a stub manager for area tests
    And I create an Area with two rooms connected north-south
    When I render rooms map for north-south rooms
    Then the rooms map should contain vertical exit arrows

  Scenario: render_rooms draws east-west exits
    Given I have a stub manager for area tests
    And I create an Area with two rooms connected east-west
    When I render rooms map for east-west rooms
    Then the rooms map should contain horizontal exit arrows

  Scenario: render_rooms draws one-way north exit
    Given I have a stub manager for area tests
    And I create an Area with one-way north exit
    When I render rooms map for one-way north
    Then the rooms map should contain an up arrow

  Scenario: render_rooms draws one-way south exit
    Given I have a stub manager for area tests
    And I create an Area with one-way south exit
    When I render rooms map for one-way south
    Then the rooms map should contain a down arrow

  Scenario: render_rooms draws one-way west exit
    Given I have a stub manager for area tests
    And I create an Area with one-way west exit
    When I render rooms map for one-way west
    Then the rooms map should contain a left arrow

  Scenario: render_rooms draws one-way east exit
    Given I have a stub manager for area tests
    And I create an Area with one-way east exit
    When I render rooms map for one-way east
    Then the rooms map should contain a right arrow

  Scenario: render_rooms draws rooms with no shared exits
    Given I have a stub manager for area tests
    And I create an Area with adjacent rooms but no exits between them
    When I render rooms map for no-exit rooms
    Then the rooms map should contain wall characters

  Scenario: render_room with nil room
    Given I have a stub manager for area tests
    And I create a new Area
    When I call render_room with nil room
    Then the render_room result should be three spaces

  Scenario: render_room shows player marker
    Given I have a stub manager for area tests
    And I create a new Area with a room containing the player
    When I call render_room for the player room
    Then the render_room result should contain the me marker

  Scenario: render_room shows mob marker
    Given I have a stub manager for area tests
    And I create a new Area with a room containing mobs
    When I call render_room for the mob room
    Then the render_room result should contain the mob marker

  Scenario: render_room shows other player marker
    Given I have a stub manager for area tests
    And I create a new Area with a room containing another player
    When I call render_room for the other player room
    Then the render_room result should contain the player marker

  Scenario: render_room shows nonstandard exit marker
    Given I have a stub manager for area tests
    And I create a new Area with a room with nonstandard exits
    When I call render_room for the nonstandard exit room
    Then the render_room result should contain the exit marker

  Scenario: render_room shows up exit marker
    Given I have a stub manager for area tests
    And I create a new Area with a room with up exit
    When I call render_room for the up exit room
    Then the render_room result should contain the up exit marker

  Scenario: render_room shows down exit marker
    Given I have a stub manager for area tests
    And I create a new Area with a room with down exit
    When I call render_room for the down exit room
    Then the render_room result should contain the down exit marker

  Scenario: render_room shows zone change and down exit on right
    Given I have a stub manager for area tests
    And I create a new Area with a room with zone change and down exit
    When I call render_room for the zone change down room
    Then the render_room result should have exit markers on both sides

  Scenario: render_room shows zone change and up exit override
    Given I have a stub manager for area tests
    And I create a new Area with a room with zone change and up exit
    When I call render_room for the zone change up room
    Then the render_room result should have zone exit on left

  Scenario: room_has_nonstandard_exits returns false for standard exits
    Given I have a stub manager for area tests
    And I create a new Area
    When I check nonstandard exits on a room with only cardinal exits
    Then the result should be false

  Scenario: room_has_nonstandard_exits returns true for nonstandard exits
    Given I have a stub manager for area tests
    And I create a new Area
    When I check nonstandard exits on a room with a portal exit
    Then the result should be true

  Scenario: render_rooms all border character combinations
    Given I have a stub manager for area tests
    And I create an Area for border character testing
    When I render the border test map
    Then the rooms map should contain various border characters

  Scenario: render_rooms handles only-west-room configuration
    Given I have a stub manager for area tests
    And I create an Area with only a west room
    When I render rooms map for only west room
    Then the rooms map should contain right cap border

  Scenario: render_rooms handles only-northwest-room configuration
    Given I have a stub manager for area tests
    And I create an Area with only a northwest room
    When I render rooms map for only northwest room
    Then the rooms map should contain bottom-right corner border

  Scenario: render_rooms handles only-north-room configuration
    Given I have a stub manager for area tests
    And I create an Area with only a north room
    When I render rooms map for only north room
    Then the rooms map should contain bottom-left corner border

  Scenario: render_rooms handles northwest-and-west rooms
    Given I have a stub manager for area tests
    And I create an Area with northwest and west rooms
    When I render rooms map for northwest-west rooms
    Then the rooms map should contain right-tee border

  Scenario: render_rooms handles northwest-and-north rooms
    Given I have a stub manager for area tests
    And I create an Area with northwest and north rooms
    When I render rooms map for northwest-north rooms
    Then the rooms map should contain bottom-tee border
