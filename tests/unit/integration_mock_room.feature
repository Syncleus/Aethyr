Feature: IntegrationMockRoom lightweight test double
  IntegrationMockRoom is a simple stand-in for a real Room object
  used in integration tests. It supports initialization with defaults,
  accessor methods, is_a? delegation, and marshal/rehydrate round-trips.

  # --- initialize (defaults) ------------------------------------------------
  Scenario: Initialize with only goid uses sensible defaults
    Given I create an imr with goid "room_1"
    Then the imr goid should be "room_1"
    And the imr name should be "Room room_1"
    And the imr coordinates should be 0 and 0
    And the imr container_goid should be "world_area"

  # --- initialize (explicit values) -----------------------------------------
  Scenario: Initialize with all explicit arguments
    Given I create an imr with goid "room_2" name "Dungeon" coordinates 3 and 5 and container "zone_a"
    Then the imr goid should be "room_2"
    And the imr name should be "Dungeon"
    And the imr coordinates should be 3 and 5
    And the imr container_goid should be "zone_a"

  # --- game_object_id -------------------------------------------------------
  Scenario: game_object_id returns goid
    Given I create an imr with goid "room_3"
    Then the imr game_object_id should equal its goid

  # --- admin ----------------------------------------------------------------
  Scenario: admin returns false
    Given I create an imr with goid "room_4"
    Then the imr admin should be false

  # --- room -----------------------------------------------------------------
  Scenario: room returns container_goid
    Given I create an imr with goid "room_5" name "Hall" coordinates 1 and 1 and container "area_b"
    Then the imr room should be "area_b"

  # --- container ------------------------------------------------------------
  Scenario: container returns container_goid
    Given I create an imr with goid "room_6" name "Tower" coordinates 2 and 3 and container "area_c"
    Then the imr container should be "area_c"

  # --- is_a? (Room) ---------------------------------------------------------
  Scenario: is_a? returns true for Aethyr Room class
    Given I create an imr with goid "room_7"
    Then the imr is_a Room should be true

  # --- is_a? (other class) --------------------------------------------------
  Scenario: is_a? falls through to super for non-Room class
    Given I create an imr with goid "room_8"
    Then the imr is_a String should be false

  # --- marshal_dump ---------------------------------------------------------
  Scenario: marshal_dump returns a hash of attributes
    Given I create an imr with goid "room_9" name "Cave" coordinates 4 and 7 and container "zone_x"
    Then the imr marshal_dump should contain all attributes

  # --- marshal_load with symbol keys ----------------------------------------
  Scenario: marshal_load restores state from symbol-keyed hash
    Given I create an imr with goid "room_10"
    When I marshal_load the imr with symbol keys goid "room_loaded" name "Loaded Room" coordinates 9 and 8 and container "zone_l"
    Then the imr goid should be "room_loaded"
    And the imr name should be "Loaded Room"
    And the imr coordinates should be 9 and 8
    And the imr container_goid should be "zone_l"

  # --- marshal_load with string keys ----------------------------------------
  Scenario: marshal_load restores state from string-keyed hash
    Given I create an imr with goid "room_11"
    When I marshal_load the imr with string keys goid "room_str" name "String Room" coordinates 1 and 2 and container "zone_s"
    Then the imr goid should be "room_str"
    And the imr name should be "String Room"
    And the imr coordinates should be 1 and 2
    And the imr container_goid should be "zone_s"

  # --- marshal_load defaults ------------------------------------------------
  Scenario: marshal_load falls back to defaults for missing keys
    Given I create an imr with goid "room_12"
    When I marshal_load the imr with minimal data goid "room_min" and name "Minimal"
    Then the imr coordinates should be 0 and 0
    And the imr container_goid should be "world_area"

  # --- rehydrate with symbol keys -------------------------------------------
  Scenario: rehydrate updates from symbol-keyed data
    Given I create an imr with goid "room_13"
    When I rehydrate the imr with symbol keys goid "rh_sym" name "Rehydrated" coordinates 6 and 3 and container "zone_r"
    Then the imr goid should be "rh_sym"
    And the imr name should be "Rehydrated"
    And the imr coordinates should be 6 and 3
    And the imr container_goid should be "zone_r"

  # --- rehydrate with string keys -------------------------------------------
  Scenario: rehydrate updates from string-keyed data
    Given I create an imr with goid "room_14"
    When I rehydrate the imr with string keys goid "rh_str" name "StrRehydrated" coordinates 7 and 4 and container "zone_q"
    Then the imr goid should be "rh_str"
    And the imr name should be "StrRehydrated"
    And the imr coordinates should be 7 and 4
    And the imr container_goid should be "zone_q"

  # --- rehydrate with nil data ----------------------------------------------
  Scenario: rehydrate with nil data returns self unchanged
    Given I create an imr with goid "room_15" name "Unchanged" coordinates 5 and 5 and container "zone_u"
    When I rehydrate the imr with nil data
    Then the imr goid should be "room_15"
    And the imr name should be "Unchanged"
    And the imr coordinates should be 5 and 5
    And the imr container_goid should be "zone_u"

  # --- rehydrate returns self -----------------------------------------------
  Scenario: rehydrate returns self
    Given I create an imr with goid "room_16"
    When I rehydrate the imr with symbol keys goid "room_16b" name "Self" coordinates 0 and 0 and container "world_area"
    Then the imr rehydrate result should be the same object

  # --- rehydrate falls back to existing values ------------------------------
  Scenario: rehydrate keeps existing values when keys are missing
    Given I create an imr with goid "room_17" name "Keeper" coordinates 8 and 9 and container "zone_k"
    When I rehydrate the imr with empty data
    Then the imr goid should be "room_17"
    And the imr name should be "Keeper"
    And the imr coordinates should be 8 and 9
    And the imr container_goid should be "zone_k"

  # --- marshal round-trip ---------------------------------------------------
  Scenario: marshal_dump then marshal_load round-trips correctly
    Given I create an imr with goid "room_rt" name "RoundTrip" coordinates 11 and 22 and container "zone_rt"
    When I round-trip the imr through marshal_dump and marshal_load
    Then the imr goid should be "room_rt"
    And the imr name should be "RoundTrip"
    And the imr coordinates should be 11 and 22
    And the imr container_goid should be "zone_rt"
