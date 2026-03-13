Feature: Event Sourcing Projections
  In order to maintain an optimized read model for querying game state
  As a developer of the Aethyr engine
  I want the projectors to correctly process events and update records

  # ── GameObjectProjector ──

  Scenario: GameObjectProjector creates a record on GameObjectCreated
    Given a GameObjectProjector with a mock persistor
    When it receives a GameObjectCreated event
    Then a game_objects record should be created with the correct attributes

  Scenario: GameObjectProjector updates a single attribute on GameObjectAttributeUpdated
    Given a GameObjectProjector with a mock persistor
    When it receives a GameObjectAttributeUpdated event
    Then the game_objects record attributes should be updated with the single attribute

  Scenario: GameObjectProjector updates multiple attributes on GameObjectAttributesUpdated
    Given a GameObjectProjector with a mock persistor
    When it receives a GameObjectAttributesUpdated event
    Then the game_objects record attributes should be updated with the merged attributes

  Scenario: GameObjectProjector updates the container on GameObjectContainerUpdated
    Given a GameObjectProjector with a mock persistor
    When it receives a GameObjectContainerUpdated event
    Then the game_objects record container_id should be updated

  Scenario: GameObjectProjector marks record deleted on GameObjectDeleted
    Given a GameObjectProjector with a mock persistor
    When it receives a GameObjectDeleted event
    Then the game_objects record should be marked as deleted

  # ── PlayerProjector ──

  Scenario: PlayerProjector creates a record on PlayerCreated
    Given a PlayerProjector with a mock persistor
    When it receives a PlayerCreated event
    Then a players record should be created with the correct player attributes

  Scenario: PlayerProjector updates password on PlayerPasswordUpdated
    Given a PlayerProjector with a mock persistor
    When it receives a PlayerPasswordUpdated event
    Then the players record password_hash should be updated

  Scenario: PlayerProjector updates admin status on PlayerAdminStatusUpdated
    Given a PlayerProjector with a mock persistor
    When it receives a PlayerAdminStatusUpdated event
    Then the players record admin status should be updated

  # ── RoomProjector ──

  Scenario: RoomProjector creates a record on RoomCreated
    Given a RoomProjector with a mock persistor
    When it receives a RoomCreated event
    Then a rooms record should be created with the correct room attributes

  Scenario: RoomProjector updates description on RoomDescriptionUpdated
    Given a RoomProjector with a mock persistor
    When it receives a RoomDescriptionUpdated event
    Then the rooms record description should be updated

  Scenario: RoomProjector adds an exit on RoomExitAdded
    Given a RoomProjector with a mock persistor
    When it receives a RoomExitAdded event
    Then the rooms record exits should include the new exit

  Scenario: RoomProjector removes an exit on RoomExitRemoved
    Given a RoomProjector with a mock persistor
    When it receives a RoomExitRemoved event
    Then the rooms record exits should not include the removed direction
