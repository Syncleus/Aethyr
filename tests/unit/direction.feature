Feature: Direction utility module
  The Aethyr::Direction module provides two helper methods:
  opposite_dir (returns the opposite compass direction) and
  expand_direction (expands abbreviations to full direction names).

  Background:
    Given I have a direction helper

  # --- opposite_dir: non-string input ---

  Scenario: opposite_dir returns non-string argument unchanged
    When I call opposite_dir with a non-string value
    Then the opposite result should be the same non-string value

  # --- opposite_dir: east/west ---

  Scenario: opposite_dir of "east" is "west"
    When I call opposite_dir with "east"
    Then the opposite result should be "west"

  Scenario: opposite_dir of "e" is "west"
    When I call opposite_dir with "e"
    Then the opposite result should be "west"

  Scenario: opposite_dir of "west" is "east"
    When I call opposite_dir with "west"
    Then the opposite result should be "east"

  Scenario: opposite_dir of "w" is "east"
    When I call opposite_dir with "w"
    Then the opposite result should be "east"

  # --- opposite_dir: north/south ---

  Scenario: opposite_dir of "north" is "south"
    When I call opposite_dir with "north"
    Then the opposite result should be "south"

  Scenario: opposite_dir of "n" is "south"
    When I call opposite_dir with "n"
    Then the opposite result should be "south"

  Scenario: opposite_dir of "south" is "north"
    When I call opposite_dir with "south"
    Then the opposite result should be "north"

  Scenario: opposite_dir of "s" is "north"
    When I call opposite_dir with "s"
    Then the opposite result should be "north"

  # --- opposite_dir: diagonals ---

  Scenario: opposite_dir of "northeast" is "southwest"
    When I call opposite_dir with "northeast"
    Then the opposite result should be "southwest"

  Scenario: opposite_dir of "ne" is "southwest"
    When I call opposite_dir with "ne"
    Then the opposite result should be "southwest"

  Scenario: opposite_dir of "southeast" is "northwest"
    When I call opposite_dir with "southeast"
    Then the opposite result should be "northwest"

  Scenario: opposite_dir of "se" is "northwest"
    When I call opposite_dir with "se"
    Then the opposite result should be "northwest"

  Scenario: opposite_dir of "southwest" is "northeast"
    When I call opposite_dir with "southwest"
    Then the opposite result should be "northeast"

  Scenario: opposite_dir of "sw" is "northeast"
    When I call opposite_dir with "sw"
    Then the opposite result should be "northeast"

  Scenario: opposite_dir of "northwest" is "southeast"
    When I call opposite_dir with "northwest"
    Then the opposite result should be "southeast"

  Scenario: opposite_dir of "nw" is "southeast"
    When I call opposite_dir with "nw"
    Then the opposite result should be "southeast"

  # --- opposite_dir: up/down ---

  Scenario: opposite_dir of "up" is "down"
    When I call opposite_dir with "up"
    Then the opposite result should be "down"

  Scenario: opposite_dir of "down" is "up"
    When I call opposite_dir with "down"
    Then the opposite result should be "up"

  # --- opposite_dir: in/out ---

  Scenario: opposite_dir of "in" is "out"
    When I call opposite_dir with "in"
    Then the opposite result should be "out"

  Scenario: opposite_dir of "out" is "in"
    When I call opposite_dir with "out"
    Then the opposite result should be "in"

  # --- opposite_dir: unknown direction ---

  Scenario: opposite_dir of unknown direction returns the input
    When I call opposite_dir with "around"
    Then the opposite result should be "around"

  # --- expand_direction: non-string input ---

  Scenario: expand_direction returns non-string argument unchanged
    When I call expand_direction with a non-string value
    Then the expand result should be the same non-string value

  # --- expand_direction: east/west ---

  Scenario: expand_direction of "e" is "east"
    When I call expand_direction with "e"
    Then the expand result should be "east"

  Scenario: expand_direction of "east" is "east"
    When I call expand_direction with "east"
    Then the expand result should be "east"

  Scenario: expand_direction of "w" is "west"
    When I call expand_direction with "w"
    Then the expand result should be "west"

  Scenario: expand_direction of "west" is "west"
    When I call expand_direction with "west"
    Then the expand result should be "west"

  # --- expand_direction: north/south ---

  Scenario: expand_direction of "n" is "north"
    When I call expand_direction with "n"
    Then the expand result should be "north"

  Scenario: expand_direction of "north" is "north"
    When I call expand_direction with "north"
    Then the expand result should be "north"

  Scenario: expand_direction of "s" is "south"
    When I call expand_direction with "s"
    Then the expand result should be "south"

  Scenario: expand_direction of "south" is "south"
    When I call expand_direction with "south"
    Then the expand result should be "south"

  # --- expand_direction: diagonals ---

  Scenario: expand_direction of "ne" is "northeast"
    When I call expand_direction with "ne"
    Then the expand result should be "northeast"

  Scenario: expand_direction of "northeast" is "northeast"
    When I call expand_direction with "northeast"
    Then the expand result should be "northeast"

  Scenario: expand_direction of "se" is "southeast"
    When I call expand_direction with "se"
    Then the expand result should be "southeast"

  Scenario: expand_direction of "southeast" is "southeast"
    When I call expand_direction with "southeast"
    Then the expand result should be "southeast"

  Scenario: expand_direction of "sw" is "southwest"
    When I call expand_direction with "sw"
    Then the expand result should be "southwest"

  Scenario: expand_direction of "southwest" is "southwest"
    When I call expand_direction with "southwest"
    Then the expand result should be "southwest"

  Scenario: expand_direction of "nw" is "northwest"
    When I call expand_direction with "nw"
    Then the expand result should be "northwest"

  Scenario: expand_direction of "northwest" is "northwest"
    When I call expand_direction with "northwest"
    Then the expand result should be "northwest"

  # --- expand_direction: up/down ---

  Scenario: expand_direction of "u" is "up"
    When I call expand_direction with "u"
    Then the expand result should be "up"

  Scenario: expand_direction of "up" is "up"
    When I call expand_direction with "up"
    Then the expand result should be "up"

  Scenario: expand_direction of "d" is "down"
    When I call expand_direction with "d"
    Then the expand result should be "down"

  Scenario: expand_direction of "down" is "down"
    When I call expand_direction with "down"
    Then the expand result should be "down"

  # --- expand_direction: in/out ---

  Scenario: expand_direction of "i" is "in"
    When I call expand_direction with "i"
    Then the expand result should be "in"

  Scenario: expand_direction of "in" is "in"
    When I call expand_direction with "in"
    Then the expand result should be "in"

  Scenario: expand_direction of "o" is "out"
    When I call expand_direction with "o"
    Then the expand result should be "out"

  Scenario: expand_direction of "out" is "out"
    When I call expand_direction with "out"
    Then the expand result should be "out"

  # --- expand_direction: unknown ---

  Scenario: expand_direction of unknown direction returns the input
    When I call expand_direction with "around"
    Then the expand result should be "around"
