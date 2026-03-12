Feature: CacheGary
  CacheGary extends Gary with transparent object caching. It can unload
  unused objects to storage and reload them on demand.

  Background:
    Given I require the cache_gary library

  # --- initialize -------------------------------------------------------------

  Scenario: Creating a new CacheGary sets up storage and manager
    Given I create a CacheGary with mock storage and manager
    Then the CacheGary should exist
    And the CacheGary should be empty

  # --- << (add) ---------------------------------------------------------------

  Scenario: Adding an object stores it in the CacheGary
    Given I create a CacheGary with mock storage and manager
    When I add a mock game object with goid "obj_1" to the CacheGary
    Then the CacheGary should contain goid "obj_1"
    And the CacheGary all_goids should include "obj_1"

  # --- loaded? ----------------------------------------------------------------

  Scenario: loaded? returns true for objects currently in memory
    Given I create a CacheGary with mock storage and manager
    And I add a mock game object with goid "obj_1" to the CacheGary
    Then loaded for goid "obj_1" should be true

  Scenario: loaded? returns false for objects not in memory
    Given I create a CacheGary with mock storage and manager
    Then loaded for goid "nonexistent" should be false

  # --- [] (lookup) ------------------------------------------------------------

  Scenario: Looking up a loaded object returns it from memory
    Given I create a CacheGary with mock storage and manager
    And I add a mock game object with goid "obj_1" to the CacheGary
    When I look up goid "obj_1" in the CacheGary
    Then the lookup result should not be nil
    And the lookup result goid should be "obj_1"

  Scenario: Looking up an unloaded but known goid loads from storage
    Given I create a CacheGary with mock storage and manager
    And the storage knows about goid "obj_remote"
    When I look up goid "obj_remote" in the CacheGary
    Then the lookup result should not be nil
    And the lookup result goid should be "obj_remote"

  Scenario: Looking up an unloaded goid that raises NoSuchGOID returns nil
    Given I create a CacheGary with mock storage and manager
    And the storage raises NoSuchGOID for goid "deleted_obj"
    When I look up goid "deleted_obj" in the CacheGary
    Then the lookup result should be nil

  Scenario: Looking up a completely unknown goid returns nil
    Given I create a CacheGary with mock storage and manager
    When I look up goid "unknown_goid" in the CacheGary
    Then the lookup result should be nil

  # --- delete -----------------------------------------------------------------

  Scenario: Deleting an existing object removes it from all_goids
    Given I create a CacheGary with mock storage and manager
    And I add a mock game object with goid "obj_del" to the CacheGary
    When I delete goid "obj_del" from the CacheGary
    Then the CacheGary should not contain goid "obj_del"
    And the CacheGary all_goids should not include "obj_del"

  Scenario: Deleting a non-existing object does not error
    Given I create a CacheGary with mock storage and manager
    When I delete goid "nonexistent" from the CacheGary
    Then the CacheGary should be empty

  # --- unload_extra -----------------------------------------------------------

  Scenario: unload_extra skips busy objects
    Given I create a CacheGary with mock storage and manager
    And I add a busy object with goid "busy_1" to the CacheGary
    When I call unload_extra on the CacheGary
    Then the CacheGary should contain goid "busy_1"
    And the storage should not have stored "busy_1"

  Scenario: unload_extra skips Player objects
    Given I create a CacheGary with mock storage and manager
    And I add a player object with goid "player_1" to the CacheGary
    When I call unload_extra on the CacheGary
    Then the CacheGary should contain goid "player_1"

  Scenario: unload_extra skips Mobile objects
    Given I create a CacheGary with mock storage and manager
    And I add a mobile object with goid "mobile_1" to the CacheGary
    When I call unload_extra on the CacheGary
    Then the CacheGary should contain goid "mobile_1"

  Scenario: unload_extra stores and removes object with inventory but no players or mobiles
    Given I create a CacheGary with mock storage and manager
    And I add an object with goid "chest_1" that has empty inventory and nil container
    When I call unload_extra on the CacheGary
    Then the CacheGary should not contain goid "chest_1"
    And the storage should have stored "chest_1"

  Scenario: unload_extra keeps object whose inventory contains a Player
    Given I create a CacheGary with mock storage and manager
    And I add an object with goid "room_1" that has inventory containing a Player and nil container
    When I call unload_extra on the CacheGary
    Then the CacheGary should contain goid "room_1"
    And the storage should not have stored "room_1"

  Scenario: unload_extra stores and removes object without inventory capability
    Given I create a CacheGary with mock storage and manager
    And I add an object with goid "item_1" that has no inventory and nil container
    When I call unload_extra on the CacheGary
    Then the CacheGary should not contain goid "item_1"
    And the storage should have stored "item_1"

  Scenario: unload_extra skips object with a loaded container
    Given I create a CacheGary with mock storage and manager
    And I add a player object with goid "container_1" to the CacheGary
    And I add an object with goid "child_1" whose container is "container_1"
    When I call unload_extra on the CacheGary
    Then the CacheGary should contain goid "child_1"

  Scenario: unload_extra processes object whose container is not loaded
    Given I create a CacheGary with mock storage and manager
    And I add an object with goid "orphan_1" whose container is "unloaded_container" and has no inventory
    When I call unload_extra on the CacheGary
    Then the CacheGary should not contain goid "orphan_1"
    And the storage should have stored "orphan_1"
