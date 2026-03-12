Feature: Manager component
  As a maintainer of the Aethyr engine
  I want the Manager to correctly manage game objects, players, actions, and lifecycle
  So that the game world operates reliably.

  Background:
    Given a stubbed Manager environment

  # --- constructor with objects parameter (line 67) ---------------------------
  Scenario: Initializing Manager with an objects parameter
    Then the manager game_objects should be the mock gary

  # --- submit_action without wait (lines 72-73) ------------------------------
  Scenario: Submitting an action without wait
    When I submit a manager action "act1" with priority 5
    Then the manager pending actions should contain "act1"

  # --- submit_action with wait (lines 75-76) ---------------------------------
  Scenario: Submitting an action with a wait time
    When I submit a manager action "delayed_act" with priority 3 and wait 10
    Then the manager future actions should not be empty

  # --- pop_action with no future actions ready (lines 82-83, 90) -------------
  Scenario: Popping an action from pending queue
    When I submit a manager action "act1" with priority 5
    And I pop a manager action
    Then the manager popped action should be "act1"

  # --- pop_action with future actions becoming ready (lines 82-86, 90) -------
  Scenario: Popping an action promotes expired future actions
    When I submit a manager action with past future time
    And I pop a manager action
    Then the manager popped action should be "past_future_act"

  # --- existing_goid? found in gary (line 95) --------------------------------
  Scenario: Checking existing goid found in game objects
    Given a mock object "obj1" in the manager gary
    Then manager existing_goid for "obj1" should be truthy

  # --- existing_goid? not in gary, check storage (line 95) -------------------
  Scenario: Checking existing goid falls through to storage
    Then manager existing_goid for "unknown_goid" should check storage

  # --- type_count (line 100) -------------------------------------------------
  Scenario: Getting type count from game objects
    Then manager type_count should delegate to game_objects

  # --- game_objects_count (line 105) -----------------------------------------
  Scenario: Getting game objects count
    Then manager game_objects_count should delegate to game_objects

  # --- stop (lines 110-111) --------------------------------------------------
  Scenario: Stopping the manager
    When I stop the manager
    Then the manager event_handler should be stopped
    And the manager running flag should be false

  # --- start (lines 116-117) -------------------------------------------------
  Scenario: Starting the manager
    When I stop the manager
    And I start the manager
    Then the manager event_handler should be started
    And the manager running flag should be true

  # --- save_all (lines 122-124) ----------------------------------------------
  Scenario: Saving all objects
    When I call manager save_all
    Then the manager storage should have received save_all

  # --- add_player without event sourcing (lines 138, 154-155) ----------------
  Scenario: Adding a player without event sourcing
    Given event sourcing is disabled in manager tests
    When I add a manager player "TestPlayer" with password "secret"
    Then the manager storage should have received save_player
    And the manager player should be added to game objects

  # --- add_player with event sourcing succeeding (line 147) ------------------
  Scenario: Adding a player with event sourcing that succeeds
    Given event sourcing is enabled in manager tests with succeeding Sequent stub
    When I add a manager player "ESSuccessPlayer" with password "secret"
    Then the manager storage should have received save_player
    And the event sourcing commands should have succeeded for add_player

  # --- add_player with event sourcing raising error (lines 138, 141-142, 147, 149)
  Scenario: Adding a player with event sourcing that errors
    Given event sourcing is enabled in manager tests with Sequent stub
    When I add a manager player "TestPlayer" with password "secret"
    Then the manager storage should have received save_player
    And the manager event sourcing error should be logged

  # --- set_password without event sourcing (lines 168, 183) ------------------
  Scenario: Setting password without event sourcing
    Given event sourcing is disabled in manager tests
    When I set manager password for player "TestPlayer" to "newpass"
    Then the manager storage should have received set_password

  # --- set_password with event sourcing succeeding (line 176) ----------------
  Scenario: Setting password with event sourcing that succeeds
    Given event sourcing is enabled in manager tests with succeeding Sequent stub
    When I set manager password for player object to "newpass"
    Then the manager storage should have received set_password
    And the event sourcing commands should have succeeded for set_password

  # --- set_password with event sourcing raising error (lines 168, 170-172, 176, 178)
  Scenario: Setting password with event sourcing that errors
    Given event sourcing is enabled in manager tests with Sequent stub
    When I set manager password for player object to "newpass"
    Then the manager storage should have received set_password

  # --- find_all (line 188) ---------------------------------------------------
  Scenario: Finding all objects by attribute
    Then manager find_all should delegate to game_objects

  # --- load_player (lines 195-211) -------------------------------------------
  Scenario: Loading a player who is not already logged in
    When I load manager player "newplayer" with password "pass123"
    Then the loaded player should have balance true
    And the loaded player should be alive

  # --- load_player already loaded, password match (lines 195-200) ------------
  Scenario: Loading a player who is already logged in with correct password
    Given a player "existing" is already loaded in manager
    When I load manager player "existing" with password "correctpass"
    Then the existing player should have been notified of login attempt
    And the existing player should have been dropped

  # --- load_player with negative health (lines 204-209) ---------------------
  Scenario: Loading a player with negative health resets to max
    When I load manager player with negative health
    Then the loaded player health should equal max health

  # --- check_password (line 216) ---------------------------------------------
  Scenario: Checking a password delegates to storage
    Then manager check_password should delegate to storage

  # --- player_exist? (lines 221-222) -----------------------------------------
  Scenario: Checking player existence delegates to storage
    Then manager player_exist should delegate to storage

  # --- object_loaded? (line 227) ---------------------------------------------
  Scenario: Checking if object is loaded
    Then manager object_loaded should delegate to game_objects

  # --- get_object (line 232) -------------------------------------------------
  Scenario: Getting an object by goid
    Given a mock object "obj1" in the manager gary
    Then manager get_object "obj1" should return the mock object

  # --- create_object with Container room (lines 257-259, 264-266, 309-317) ---
  Scenario: Creating an object with a Container room and Enumerable args
    When I create a manager object with container room and enumerable args
    Then the created object should be added to the game
    And the created object should be added to the room

  # --- create_object with room goid (lines 261-262, 264, 267-268) -----------
  Scenario: Creating an object with a room goid and non-enumerable args
    When I create a manager object with room goid and single arg
    Then the created object should be added to the game

  # --- create_object with no args (line 271) ---------------------------------
  Scenario: Creating an object with no args
    When I create a manager object with no args
    Then the created object should be added to the game

  # --- create_object with vars (lines 274-276) -------------------------------
  Scenario: Creating an object with instance variable overrides
    When I create a manager object with vars
    Then the created object should have the custom vars set

  # --- create_object with position (lines 311, 314) --------------------------
  Scenario: Creating an object with a position in the room
    When I create a manager object with position
    Then the created object should be added to the room with position

  # --- create_object with event sourcing succeeding (lines 290, 293-296, 301) -
  Scenario: Creating an object with event sourcing that succeeds
    Given event sourcing is enabled in manager tests with succeeding Sequent stub
    When I create a manager object with vars and event sourcing
    Then the event sourcing commands should have succeeded for create_object with vars

  # --- create_object with event sourcing raising error (lines 281, 284, 290, 305)
  Scenario: Creating an object with event sourcing enabled
    Given event sourcing is enabled in manager tests with Sequent stub
    When I create a manager object with vars and event sourcing
    Then the event sourcing commands should have been attempted

  # --- add_object non-player with room as Area (lines 323, 325, 327-331, 338, 340)
  Scenario: Adding a non-player object with room being an Area
    When I add a non-player object with area room to the manager
    Then the object should be stored by storage
    And the area room should contain the object

  # --- add_object non-player with room not Area (lines 329, 332-333) ---------
  Scenario: Adding a non-player object with room being a regular Room
    When I add a non-player object with regular room to the manager
    Then the regular room should contain the object

  # --- add_object player with nil room, former_room (lines 342-344, 347-349, 355-357)
  Scenario: Adding a player with nil room uses former room
    When I add a player object with nil room and former_room to the manager
    Then the player container should be set to former room
    And admins should be notified of player entry

  # --- add_object player with nil room, no former_room (lines 347, 350-351)
  Scenario: Adding a player with nil room and no former room uses start room
    When I add a player object with nil room and no former_room to the manager
    Then the player container should be set to start room

  # --- delete_player exists and loaded (lines 364-397) -----------------------
  Scenario: Deleting a loaded player
    When I delete a loaded manager player "delplayer"
    Then the player inventory items should be deleted
    And the player equipment items should be deleted
    And the deleted player should be removed from game objects
    And the storage should have received delete_player

  # --- delete_player not exist (lines 364-366) -------------------------------
  Scenario: Deleting a non-existent player
    When I delete a non-existent manager player "ghost"
    Then the storage should not have received delete_player

  # --- delete_player not loaded (lines 369, 371-373) -------------------------
  Scenario: Deleting a player that exists but is not loaded
    When I delete an unloaded manager player "offlineplayer"
    Then the storage should have received delete_player

  # --- delete_object without event sourcing (lines 415-465) ------------------
  Scenario: Deleting a game object with container and inventory
    Given event sourcing is disabled in manager tests
    When I delete a manager object that has container and inventory
    Then the object should be removed from its container
    And the object inventory should be moved to container room
    And the object should be removed from game objects
    And the storage should have received delete_object

  # --- delete_object with equipment (lines 452-457) --------------------------
  Scenario: Deleting a game object that has equipment
    When I delete a manager object that has equipment
    Then the equipment items should be moved to the room

  # --- delete_object with event sourcing succeeding (line 409) ----------------
  Scenario: Deleting a game object with event sourcing that succeeds
    Given event sourcing is enabled in manager tests with succeeding Sequent stub
    When I delete a simple manager object with event sourcing
    Then the event sourcing commands should have succeeded for delete_object

  # --- delete_object with event sourcing raising error (lines 403, 405-406, 411)
  Scenario: Deleting a game object with event sourcing
    Given event sourcing is enabled in manager tests with Sequent stub
    When I delete a simple manager object with event sourcing
    Then the event sourcing delete command should have been attempted

  # --- delete_object with equipment_of info (lines 434-436) ------------------
  Scenario: Deleting an object that is equipment of another object
    When I delete a manager object that is equipment of another
    Then the equipment should be removed from the owner

  # --- delete_object no room fallback to Garbage Dump (lines 439-440) --------
  Scenario: Deleting an object with no room falls back to Garbage Dump
    When I delete a manager object with no container
    Then the garbage dump should be used for inventory

  # --- drop_player (lines 471-496) -------------------------------------------
  Scenario: Dropping a player from the game
    When I drop a manager player
    Then the dropped player should be saved by storage
    And the dropped player should be removed from game objects
    And the player should receive farewell message

  # --- drop_player with nil (line 471) ---------------------------------------
  Scenario: Dropping a nil player does nothing
    When I drop a nil manager player
    Then no error should occur in manager drop

  # --- drop_player with error (lines 499-501) --------------------------------
  Scenario: Dropping a player that causes an error recovers gracefully
    When I drop a manager player that causes an error
    Then the error should be logged in manager drop

  # --- update_all (lines 510-511, 518) ---------------------------------------
  Scenario: Updating all game objects
    When I call manager update_all
    Then all game objects should have been updated
    And the calendar should have been ticked

  # --- alert_all (lines 523, 525-526) ----------------------------------------
  Scenario: Alerting all players
    When I call manager alert_all with message "Test alert"
    Then all players should receive the alert message

  # --- alert_all with lost player ignored (line 525) -------------------------
  Scenario: Alerting all players ignores players with nil container
    When I call manager alert_all with a lost player
    Then the lost player should not receive the alert

  # --- find with nil container (lines 535-536, 539) --------------------------
  Scenario: Finding an object globally
    Then manager find with nil container delegates to game_objects find

  # --- find with nil container findall (lines 535-537) -----------------------
  Scenario: Finding all objects globally by generic name
    Then manager find with nil container and findall delegates to find_all

  # --- find with HasInventory container (lines 541-542) ----------------------
  Scenario: Finding an object in a HasInventory container
    Then manager find with HasInventory container calls search_inv

  # --- find with non-GameObject string container (lines 543-548) -------------
  Scenario: Finding an object with a string container name
    Then manager find with string container resolves the container first

  # --- find with string container that resolves to nil (lines 544-546) -------
  Scenario: Finding an object with string container that does not exist
    Then manager find with non-existent string container returns nil

  # --- restart (lines 555-558) -----------------------------------------------
  Scenario: Restarting the server
    When I call manager restart
    Then the manager soft_restart should be true

  # --- time (line 563) -------------------------------------------------------
  Scenario: Getting the game time
    Then manager time should delegate to calendar

  # --- date (line 568) -------------------------------------------------------
  Scenario: Getting the game date
    Then manager date should delegate to calendar

  # --- date_at (line 573) ----------------------------------------------------
  Scenario: Getting the game date at a timestamp
    Then manager date_at should delegate to calendar

  # --- to_s (line 577) -------------------------------------------------------
  Scenario: Converting manager to string
    Then manager to_s should return "The Manager"

  # --- epoch_now private class method (line 582) -----------------------------
  Scenario: Epoch now returns current time as integer
    Then manager epoch_now should return an integer close to current time
