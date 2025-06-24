Feature: Event Sourcing System
  In order to maintain a reliable history of all game state changes
  As a developer of the Aethyr engine
  I want the event sourcing system to properly record, store, and replay events

  Background:
    Given a clean event store
    And event sourcing is enabled

  Scenario: Creating a game object emits and stores creation event
    When I create a new game object
    Then a GameObjectCreated event should be emitted
    And the event should be stored in the event store
    And the event should contain the correct object attributes

  Scenario: Updating a game object attribute emits and stores update event
    Given an existing game object
    When I update the object's long description
    Then a GameObjectAttributeUpdated event should be emitted
    And the event should be stored in the event store
    And the event should contain the updated attribute

  Scenario: Updating multiple game object attributes emits batch update event
    Given an existing game object
    When I update multiple attributes at once
    Then a GameObjectAttributesUpdated event should be emitted
    And the event should be stored in the event store
    And the event should contain all updated attributes

  Scenario: Moving an object to a new container emits container update event
    Given an existing game object
    And an existing container object
    When I move the object to the container
    Then a GameObjectContainerUpdated event should be emitted
    And the event should be stored in the event store
    And the event should reference the new container

  Scenario: Creating a player emits player-specific creation event
    When I create a new player
    Then a PlayerCreated event should be emitted
    And the event should be stored in the event store
    And the event should contain player-specific attributes

  Scenario: Updating a player's password emits password update event
    Given an existing player
    When I update the player's password
    Then a PlayerPasswordUpdated event should be emitted
    And the event should be stored in the event store
    And the event should contain the new password hash

  Scenario: Creating a room emits room-specific creation event
    When I create a new room
    Then a RoomCreated event should be emitted
    And the event should be stored in the event store
    And the event should contain room-specific attributes

  Scenario: Adding an exit to a room emits exit added event
    Given an existing room
    And another existing room
    When I add an exit between the rooms
    Then a RoomExitAdded event should be emitted
    And the event should be stored in the event store
    And the event should reference both rooms

  Scenario: Rebuilding world state from events
    Given multiple game objects with recorded events
    When I rebuild the world state from events
    Then all objects should be restored with correct attributes
    And all relationships between objects should be preserved

  Scenario: Event store falls back to file-based storage when ImmuDB is unavailable
    Given ImmuDB is not available
    When I create a new game object
    Then events should be stored in the file-based event store
    And the events should be retrievable from the file-based store

  Scenario: Event store handles errors gracefully
    Given event store operations occasionally fail
    When I perform multiple event store operations
    Then failed operations should be retried
    And persistent failures should be logged
    And the system should continue functioning
