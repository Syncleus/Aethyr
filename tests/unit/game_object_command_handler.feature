@real_sequent
Feature: GameObjectCommandHandler event sourcing command handling
  In order to ensure all game commands are properly routed to domain aggregates
  As a maintainer of the Aethyr event sourcing system
  I want every command handler block in GameObjectCommandHandler to produce the correct events

  Background:
    Given the Sequent test environment is configured for command handler testing

  Scenario: CreateGameObject command produces a GameObjectCreated event
    When I dispatch a CreateGameObject command
    Then a GameObjectCreated event should be produced with the correct attributes

  Scenario: UpdateGameObjectAttribute command produces a GameObjectAttributeUpdated event
    Given an existing game object aggregate
    When I dispatch an UpdateGameObjectAttribute command
    Then a GameObjectAttributeUpdated event should be produced with the correct key and value

  Scenario: UpdateGameObjectAttributes command produces a GameObjectAttributesUpdated event
    Given an existing game object aggregate
    When I dispatch an UpdateGameObjectAttributes command
    Then a GameObjectAttributesUpdated event should be produced with the correct attributes hash

  Scenario: UpdateGameObjectContainer command produces a GameObjectContainerUpdated event
    Given an existing game object aggregate
    When I dispatch an UpdateGameObjectContainer command
    Then a GameObjectContainerUpdated event should be produced with the correct container id

  Scenario: DeleteGameObject command produces a GameObjectDeleted event
    Given an existing game object aggregate
    When I dispatch a DeleteGameObject command
    Then a GameObjectDeleted event should be produced

  Scenario: CreatePlayer command produces PlayerCreated event
    When I dispatch a CreatePlayer command
    Then a PlayerCreated event should be produced with the correct player attributes

  Scenario: UpdatePlayerPassword command produces PlayerPasswordUpdated event
    Given an existing player aggregate
    When I dispatch an UpdatePlayerPassword command
    Then a PlayerPasswordUpdated event should be produced with the correct password hash

  Scenario: UpdatePlayerAdminStatus command produces PlayerAdminStatusUpdated event
    Given an existing player aggregate
    When I dispatch an UpdatePlayerAdminStatus command
    Then a PlayerAdminStatusUpdated event should be produced with the correct admin status

  Scenario: CreateRoom command produces RoomCreated event
    When I dispatch a CreateRoom command
    Then a RoomCreated event should be produced with the correct room attributes

  Scenario: UpdateRoomDescription command produces RoomDescriptionUpdated event
    Given an existing room aggregate
    When I dispatch an UpdateRoomDescription command
    Then a RoomDescriptionUpdated event should be produced with the correct description

  Scenario: AddRoomExit command produces RoomExitAdded event
    Given an existing room aggregate
    When I dispatch an AddRoomExit command
    Then a RoomExitAdded event should be produced with the correct direction and target

  Scenario: RemoveRoomExit command produces RoomExitRemoved event
    Given an existing room aggregate with an exit
    When I dispatch a RemoveRoomExit command
    Then a RoomExitRemoved event should be produced with the correct direction
