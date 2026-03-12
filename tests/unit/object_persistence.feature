Feature: Object persistence via StorageMachine
  The StorageMachine provides GDBM-backed persistence for all game objects,
  including players, rooms, and regular objects with inventories and equipment.

  # -------------------------------------------------------------------
  # Initialization
  # -------------------------------------------------------------------

  Scenario: Storage machine initializes with default path
    Given I require the storage library
    When I create a new storage machine with a temp directory
    Then the storage machine should be ready

  # -------------------------------------------------------------------
  # Single object store / retrieve / delete
  # -------------------------------------------------------------------

  Scenario: Storing and retrieving a game object by GOID
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage store a basic game object
    Then I storage should be able to look up its type by GOID
    And I storage should be able to load the object back

  Scenario: Storing a game object increments the saved counter
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage store a basic game object
    Then the storage saved counter should be positive

  Scenario: Storing an object with equipment saves equipment too
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage store an object that has equipment
    Then the equipment items should also be stored

  Scenario: Deleting an object by GOID string
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage store a basic game object
    When I storage delete the object by GOID string
    Then the storage type lookup should return nil for that GOID

  Scenario: Deleting an object by game object reference
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage store a basic game object
    When I storage delete the object by game object reference
    Then the storage type lookup should return nil for that GOID

  Scenario: Deleting a non-existent object by GOID returns nil
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage delete a non-existent GOID
    Then the storage delete result should be nil

  Scenario: Type lookup for non-existent GOID returns nil
    Given I require the storage library
    And I create a new storage machine with a temp directory
    Then the storage type lookup for a random GOID should return nil

  # -------------------------------------------------------------------
  # Player persistence
  # -------------------------------------------------------------------

  Scenario: Saving and loading a player with password
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage save a player named "testwarrior" with password "s3cret"
    Then the storage player "testwarrior" should exist
    And I storage should be able to load player "testwarrior" with password "s3cret"

  Scenario: Saving a player stores inventory items
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage save a player with inventory items
    Then all player inventory items should be persisted

  Scenario: Saving a player without password skips password store
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage save a player named "nopass" without a password
    Then the storage player "nopass" should exist

  Scenario: Player existence check returns false for unknown player
    Given I require the storage library
    And I create a new storage machine with a temp directory
    Then the storage player "nobody" should not exist

  Scenario: Loading a player with wrong password raises BadPassword
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage save a player named "guardedplayer" with password "correct"
    When I storage try to load player "guardedplayer" with wrong password "wrong"
    Then a storage BadPassword error should have been raised

  Scenario: Loading a non-existent player raises UnknownCharacter
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage try to load non-existent player "ghost"
    Then a storage UnknownCharacter error should have been raised

  # -------------------------------------------------------------------
  # Password management
  # -------------------------------------------------------------------

  Scenario: Setting password using a player name string
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage save a player named "alice" with password "oldpass"
    When I storage set password for player name "alice" to "newpass"
    Then I storage should be able to load player "alice" with password "newpass"

  Scenario: Setting password using a player object
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage save a player named "bob" with password "oldpass"
    When I storage set password for player object "bob" to "newpass2"
    Then I storage should be able to load player "bob" with password "newpass2"

  Scenario: Checking a correct password returns true
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage save a player named "checker" with password "rightpw"
    Then storage check_password for "checker" with "rightpw" should be true

  Scenario: Checking a wrong password returns false
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage save a player named "checker2" with password "rightpw"
    Then storage check_password for "checker2" with "wrongpw" should be false

  Scenario: Checking password for unknown player raises error
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage check password for unknown player "phantom"
    Then a storage UnknownCharacter error should have been raised

  # -------------------------------------------------------------------
  # Deleting players
  # -------------------------------------------------------------------

  Scenario: Deleting an existing player
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage save a player named "deleteme" with password "pass"
    When I storage delete player "deleteme"
    Then the storage player "deleteme" should not exist

  Scenario: Deleting a non-existent player returns nil
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage delete player "nonexistent"
    Then the storage player delete result should be nil

  # -------------------------------------------------------------------
  # Loading objects with inventory and equipment
  # -------------------------------------------------------------------

  Scenario: Loading an object restores its inventory
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage store a container with inventory items
    And I storage load the container back
    Then the loaded container should have its inventory restored

  Scenario: Loading an object restores its equipment
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage store a living object with equipment items
    And I storage load the living object back
    Then the loaded living object should have its equipment restored

  Scenario: Loading object with missing container falls back to start room
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage store an object referencing a non-existent container
    And I storage load that orphaned object
    Then the loaded object container should be the start room

  Scenario: Loading a non-existent GOID raises NoSuchGOID
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage try to load a non-existent GOID
    Then a storage NoSuchGOID error should have been raised

  Scenario: Loading object with goid but nil data raises ObjectLoadError
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage try to load a GOID with corrupted data
    Then a storage ObjectLoadError should have been raised

  # -------------------------------------------------------------------
  # Bulk operations
  # -------------------------------------------------------------------

  Scenario: Load all objects from storage
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage have stored several game objects
    When I storage load all objects
    Then all stored objects should be present in the loaded collection

  Scenario: Load all objects excluding players by default
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage have stored objects including a player
    When I storage load all objects without players
    Then the loaded collection should not contain players

  Scenario: Load all objects including players when requested
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage have stored objects including a player
    When I storage load all objects with players
    Then the loaded collection should contain players

  Scenario: Save all objects in a Gary
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage save all objects from a Gary
    Then all objects should be persisted in storage

  Scenario: Load all with pre-existing game objects Gary
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage have stored several game objects
    When I storage load all into a pre-existing Gary
    Then the pre-existing Gary should contain all loaded objects

  # -------------------------------------------------------------------
  # Inventory and equipment loading helpers
  # -------------------------------------------------------------------

  Scenario: load_inv with object that has no inventory method
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage call load_inv on an object without inventory
    Then load_inv should return without error

  Scenario: load_inv with nil inventory
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage call load_inv on an object with nil inventory
    Then the object should get an empty inventory

  Scenario: load_inv with empty inventory
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage call load_inv on an object with empty inventory
    Then the object should keep an empty inventory with capacity

  Scenario: load_inv with populated inventory resolves objects
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage call load_inv with populated inventory and game objects
    Then the inventory items should be resolved from game objects

  Scenario: load_equipment with object that has no equipment method
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage call load_equipment on an object without equipment
    Then load_equipment should return without error

  Scenario: load_inv with inventory containing unloaded objects logs warning
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage call load_inv with an item not in game objects
    Then load_inv should skip the unloaded item gracefully

  Scenario: load_equipment delegates to load_inv
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage call load_equipment on an equipped object
    Then the equipment inventory should be processed

  # -------------------------------------------------------------------
  # Open store modes
  # -------------------------------------------------------------------

  Scenario: open_store in read-only mode
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage open a store in read-only mode
    Then the store should be accessible for reading

  Scenario: open_store in read-write mode
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage open a store in read-write mode and write data
    Then the written data should be readable afterward

  # -------------------------------------------------------------------
  # Dangerous bulk update
  # -------------------------------------------------------------------

  Scenario: update_all_objects modifies and re-saves every object
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage have stored several game objects
    When I storage call update_all_objects with a modification block
    Then every object should reflect the modification

  # -------------------------------------------------------------------
  # Event store migration guard
  # -------------------------------------------------------------------

  Scenario: migrate_to_event_store returns false when disabled
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage call migrate_to_event_store with event sourcing disabled
    Then the migration result should be false

  Scenario: migrate_to_event_store returns false when Sequent is unavailable
    Given I require the storage library
    And I create a new storage machine with a temp directory
    When I storage call migrate_to_event_store with Sequent unavailable
    Then the migration result should be false

  Scenario: migrate_to_event_store migrates all objects when enabled
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage enable event sourcing with mock Sequent
    And I storage have stored several game objects for migration
    When I storage call migrate_to_event_store with mock Sequent
    Then the migration should succeed
    And migration commands should have been created for all objects

  # -------------------------------------------------------------------
  # Event sourcing integration paths
  # -------------------------------------------------------------------

  Scenario: store_object with event sourcing enabled
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage enable event sourcing with mock Sequent
    When I storage store a basic game object with event sourcing
    Then the object should be stored in GDBM and event store

  Scenario: save_player with event sourcing enabled
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage enable event sourcing with mock Sequent
    When I storage save player with event sourcing enabled
    Then the player should be stored in both GDBM and event store

  Scenario: set_password with event sourcing enabled
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage enable event sourcing with mock Sequent
    And I storage save a player named "evplayer" with password "initpw"
    When I storage set password with event sourcing for "evplayer" to "newpw"
    Then the password update command should have been sent to event store

  Scenario: delete_object with event sourcing enabled
    Given I require the storage library
    And I create a new storage machine with a temp directory
    And I storage enable event sourcing with mock Sequent
    And I storage store a basic game object with event sourcing
    When I storage delete the object with event sourcing by GOID string
    Then the delete command should have been sent to event store
