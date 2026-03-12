Feature: GetCommand action
  In order to let players pick up objects from rooms and containers
  As a maintainer of the Aethyr engine
  I want GetCommand#action to correctly handle all get scenarios.

  Background:
    Given a stubbed GetCommand environment

  # --- Direct get: object not found (lines 14-16, 18-20) ----------------------
  Scenario: Getting an object that does not exist
    Given get target object is not found
    When the GetCommand action is invoked
    Then the get player should see "There is no"

  # --- Direct get: object not movable (lines 14-16, 18, 21-23) ----------------
  Scenario: Getting an object that is not movable
    Given a get target object "heavy boulder" that is not movable
    When the GetCommand action is invoked
    Then the get player should see "You cannot take heavy boulder"

  # --- Direct get: inventory full (lines 14-16, 18, 21, 24-26) ----------------
  Scenario: Getting an object when inventory is full
    Given a get target object "gold coin" that is movable
    And the get player inventory is full
    When the GetCommand action is invoked
    Then the get player should see "You cannot hold any more objects"

  # --- Direct get: success (lines 9, 14-16, 29-31, 33-35) --------------------
  Scenario: Successfully getting an object from the room
    Given a get target object "gold coin" that is movable
    When the GetCommand action is invoked
    Then the room should have an out_event with to_player "You take gold coin."
    And the room should have an out_event with to_other containing "takes gold coin."
    And the object should be removed from the room
    And the object should be in the player inventory

  # --- From container: container not found (lines 37-39, 41-43) ----------------
  Scenario: Getting from a container that does not exist
    Given get from container "chest" that is not found
    When the GetCommand action is invoked with from
    Then the get player should see "There is no chest"

  # --- From container: not a Container (lines 37-38, 41, 44-46) ---------------
  Scenario: Getting from something that is not a container
    Given get from target "rock" that is not a container
    When the GetCommand action is invoked with from
    Then the get player should see "Not sure how to do that"

  # --- From container: container is closed (lines 37-38, 41, 44, 47-49) -------
  Scenario: Getting from a closed container
    Given get from container "chest" that is closed
    When the GetCommand action is invoked with from
    Then the get player should see "You will need to open it first"

  # --- From container: object not found (lines 37-38, 52, 54-56) ---------------
  Scenario: Getting an object that is not in the container
    Given get from container "chest" that is open
    And get target object in container is not found
    When the GetCommand action is invoked with from
    Then the get player should see "There is no shiny gem in the chest"

  # --- From container: object not movable (lines 37-38, 52, 54, 57-59) --------
  Scenario: Getting an object from container that is not movable
    Given get from container "chest" that is open
    And get target object in container "rusty bolt" is not movable
    When the GetCommand action is invoked with from
    Then the get player should see "You cannot take the rusty bolt"

  # --- From container: inventory full (lines 37-38, 52, 54, 57, 60-62) --------
  Scenario: Getting from container when inventory is full
    Given get from container "chest" that is open
    And get target object in container "gold coin" is movable
    And the get player inventory is full
    When the GetCommand action is invoked with from
    Then the get player should see "You cannot hold any more objects"

  # --- From container: success (lines 37-38, 52, 65-66, 68-70) ---------------
  Scenario: Successfully getting an object from a container
    Given get from container "chest" that is open
    And get target object in container "gold coin" is movable
    When the GetCommand action is invoked with from
    Then the room should have an out_event with to_player "You take gold coin from chest."
    And the room should have an out_event with to_other containing "takes gold coin from chest."
    And the object should be removed from the container
    And the object should be added to the player inventory
