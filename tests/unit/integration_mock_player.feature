Feature: IntegrationMockPlayer lightweight test double
  IntegrationMockPlayer is a simple stand-in for a real Player object
  used in integration tests. It supports initialization with defaults,
  accessor methods, is_a? delegation, and marshal/rehydrate round-trips.

  # --- initialize (defaults) ------------------------------------------------
  Scenario: Initialize with only goid uses sensible defaults
    Given I create an imp with goid "player_1"
    Then the imp goid should be "player_1"
    And the imp name should be "Player player_1"
    And the imp container_goid should be nil
    And the imp info should be an OpenStruct

  # --- initialize (explicit values) -----------------------------------------
  Scenario: Initialize with all explicit arguments
    Given I create an imp with goid "player_2" name "Hero" and container "room_a"
    Then the imp goid should be "player_2"
    And the imp name should be "Hero"
    And the imp container_goid should be "room_a"

  # --- game_object_id -------------------------------------------------------
  Scenario: game_object_id returns goid
    Given I create an imp with goid "player_3"
    Then the imp game_object_id should equal its goid

  # --- admin ----------------------------------------------------------------
  Scenario: admin returns false
    Given I create an imp with goid "player_4"
    Then the imp admin should be false

  # --- room -----------------------------------------------------------------
  Scenario: room returns container_goid
    Given I create an imp with goid "player_5" name "Mage" and container "room_b"
    Then the imp room should be "room_b"

  # --- container ------------------------------------------------------------
  Scenario: container returns container_goid
    Given I create an imp with goid "player_6" name "Thief" and container "room_c"
    Then the imp container should be "room_c"

  # --- is_a? (Player) -------------------------------------------------------
  Scenario: is_a? returns true for Aethyr Player class
    Given I create an imp with goid "player_7"
    Then the imp is_a Player should be true

  # --- is_a? (other class) --------------------------------------------------
  Scenario: is_a? falls through to super for non-Player class
    Given I create an imp with goid "player_8"
    Then the imp is_a String should be false

  # --- marshal_dump ---------------------------------------------------------
  Scenario: marshal_dump returns a hash of attributes
    Given I create an imp with goid "player_9" name "Dumper" and container "room_d"
    Then the imp marshal_dump should contain all attributes

  # --- marshal_load with symbol keys ----------------------------------------
  Scenario: marshal_load restores state from symbol-keyed hash
    Given I create an imp with goid "player_10"
    When I marshal_load the imp with symbol keys goid "p_loaded" name "Loaded" container "room_l" and info
    Then the imp goid should be "p_loaded"
    And the imp name should be "Loaded"
    And the imp container_goid should be "room_l"

  # --- marshal_load with string keys ----------------------------------------
  Scenario: marshal_load restores state from string-keyed hash
    Given I create an imp with goid "player_11"
    When I marshal_load the imp with string keys goid "p_str" name "StrPlayer" container "room_s" and info
    Then the imp goid should be "p_str"
    And the imp name should be "StrPlayer"
    And the imp container_goid should be "room_s"

  # --- marshal_load defaults ------------------------------------------------
  Scenario: marshal_load falls back to defaults for missing keys
    Given I create an imp with goid "player_12"
    When I marshal_load the imp with minimal data goid "p_min" and name "Minimal"
    Then the imp container_goid should be nil
    And the imp info should be an OpenStruct

  # --- rehydrate with symbol keys -------------------------------------------
  Scenario: rehydrate updates from symbol-keyed data
    Given I create an imp with goid "player_13"
    When I rehydrate the imp with symbol keys goid "rh_sym" name "Rehydrated" container "room_r" and info
    Then the imp goid should be "rh_sym"
    And the imp name should be "Rehydrated"
    And the imp container_goid should be "room_r"

  # --- rehydrate with string keys -------------------------------------------
  Scenario: rehydrate updates from string-keyed data
    Given I create an imp with goid "player_14"
    When I rehydrate the imp with string keys goid "rh_str" name "StrRehydrated" container "room_q" and info
    Then the imp goid should be "rh_str"
    And the imp name should be "StrRehydrated"
    And the imp container_goid should be "room_q"

  # --- rehydrate with nil data ----------------------------------------------
  Scenario: rehydrate with nil data returns self unchanged
    Given I create an imp with goid "player_15" name "Unchanged" and container "room_u"
    When I rehydrate the imp with nil data
    Then the imp goid should be "player_15"
    And the imp name should be "Unchanged"
    And the imp container_goid should be "room_u"

  # --- rehydrate returns self -----------------------------------------------
  Scenario: rehydrate returns self
    Given I create an imp with goid "player_16"
    When I rehydrate the imp with symbol keys goid "player_16b" name "Self" container "room_x" and info
    Then the imp rehydrate result should be the same object

  # --- rehydrate falls back to existing values ------------------------------
  Scenario: rehydrate keeps existing values when keys are missing
    Given I create an imp with goid "player_17" name "Keeper" and container "room_k"
    When I rehydrate the imp with empty data
    Then the imp goid should be "player_17"
    And the imp name should be "Keeper"
    And the imp container_goid should be "room_k"

  # --- marshal round-trip ---------------------------------------------------
  Scenario: marshal_dump then marshal_load round-trips correctly
    Given I create an imp with goid "p_rt" name "RoundTrip" and container "room_rt"
    When I round-trip the imp through marshal_dump and marshal_load
    Then the imp goid should be "p_rt"
    And the imp name should be "RoundTrip"
    And the imp container_goid should be "room_rt"

  # --- output mock ----------------------------------------------------------
  Scenario: output does not raise an error
    Given I create an imp with goid "player_18"
    Then calling output on the imp should not raise

  # --- quit mock ------------------------------------------------------------
  Scenario: quit does not raise an error
    Given I create an imp with goid "player_19"
    Then calling quit on the imp should not raise

  # --- attr_accessor for info -----------------------------------------------
  Scenario: info can be set and retrieved
    Given I create an imp with goid "player_20"
    When I set the imp info to a custom OpenStruct
    Then the imp info name should be "custom"
