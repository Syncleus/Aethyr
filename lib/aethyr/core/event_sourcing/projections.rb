require 'sequent'
require 'aethyr/core/event_sourcing/events'

module Aethyr
  module Core
    module EventSourcing
      # @author Aethyr Development Team
      # @since 1.0.0
      #
      # Projector for game objects.
      #
      # This class maintains a projection of game objects by processing
      # events related to game object creation, updates, and deletion.
      # It creates and updates records in the game_objects table to provide
      # an optimized read model for querying game objects.
      #
      # The projector handles the following events:
      # - GameObjectCreated: Creates a new record for the game object
      # - GameObjectAttributeUpdated: Updates a single attribute of a game object
      # - GameObjectAttributesUpdated: Updates multiple attributes of a game object
      # - GameObjectContainerUpdated: Updates the container of a game object
      # - GameObjectDeleted: Marks a game object as deleted
      class GameObjectProjector < Sequent::Projector
        manages_tables :game_objects
        
        # @param event [GameObjectCreated] The event to handle
        # Creates a new record in the game_objects table for a newly created game object.
        # This method is called when a GameObjectCreated event is processed.
        on GameObjectCreated do |event|
          create_record(
            :game_objects,
            aggregate_id: event.aggregate_id,
            name: event.name,
            generic: event.generic,
            container_id: event.container_id,
            attributes: Marshal.dump(event.attributes || {}),
            deleted: false
          )
        end
        
        # @param event [GameObjectAttributeUpdated] The event to handle
        # Updates a single attribute of a game object in the game_objects table.
        # This method is called when a GameObjectAttributeUpdated event is processed.
        on GameObjectAttributeUpdated do |event|
          update_all_records(
            :game_objects,
            {aggregate_id: event.aggregate_id},
            {attributes: -> (record) { Marshal.dump(Marshal.load(record.attributes).merge(event.key => event.value)) }}
          )
        end
        
        # @param event [GameObjectAttributesUpdated] The event to handle
        # Updates multiple attributes of a game object in the game_objects table.
        # This method is called when a GameObjectAttributesUpdated event is processed.
        on GameObjectAttributesUpdated do |event|
          update_all_records(
            :game_objects,
            {aggregate_id: event.aggregate_id},
            {attributes: -> (record) { 
              current_attrs = Marshal.load(record.attributes)
              Marshal.dump(current_attrs.merge(event.attributes)) 
            }}
          )
        end
        
        # @param event [GameObjectContainerUpdated] The event to handle
        # Updates the container of a game object in the game_objects table.
        # This method is called when a GameObjectContainerUpdated event is processed.
        on GameObjectContainerUpdated do |event|
          update_all_records(
            :game_objects,
            {aggregate_id: event.aggregate_id},
            {container_id: event.container_id}
          )
        end
        
        # @param event [GameObjectDeleted] The event to handle
        # Marks a game object as deleted in the game_objects table.
        # This method is called when a GameObjectDeleted event is processed.
        on GameObjectDeleted do |event|
          update_all_records(
            :game_objects,
            {aggregate_id: event.aggregate_id},
            {deleted: true}
          )
        end
      end
      
      # @author Aethyr Development Team
      # @since 1.0.0
      #
      # Projector for players.
      #
      # This class maintains a projection of players by processing
      # events related to player creation and updates.
      # It creates and updates records in the players table to provide
      # an optimized read model for querying players.
      #
      # The projector handles the following events:
      # - PlayerCreated: Creates a new record for the player
      # - PlayerPasswordUpdated: Updates a player's password hash
      # - PlayerAdminStatusUpdated: Updates a player's admin status
      class PlayerProjector < Sequent::Projector
        manages_tables :players
        
        # @param event [PlayerCreated] The event to handle
        # Creates a new record in the players table for a newly created player.
        # This method is called when a PlayerCreated event is processed.
        on PlayerCreated do |event|
          create_record(
            :players,
            aggregate_id: event.aggregate_id,
            password_hash: event.password_hash,
            admin: event.admin
          )
        end
        
        # @param event [PlayerPasswordUpdated] The event to handle
        # Updates a player's password hash in the players table.
        # This method is called when a PlayerPasswordUpdated event is processed.
        on PlayerPasswordUpdated do |event|
          update_all_records(
            :players,
            {aggregate_id: event.aggregate_id},
            {password_hash: event.password_hash}
          )
        end
        
        # @param event [PlayerAdminStatusUpdated] The event to handle
        # Updates a player's admin status in the players table.
        # This method is called when a PlayerAdminStatusUpdated event is processed.
        on PlayerAdminStatusUpdated do |event|
          update_all_records(
            :players,
            {aggregate_id: event.aggregate_id},
            {admin: event.admin}
          )
        end
      end
      
      # @author Aethyr Development Team
      # @since 1.0.0
      #
      # Projector for rooms.
      #
      # This class maintains a projection of rooms by processing
      # events related to room creation, description updates, and exit management.
      # It creates and updates records in the rooms table to provide
      # an optimized read model for querying rooms.
      #
      # The projector handles the following events:
      # - RoomCreated: Creates a new record for the room
      # - RoomDescriptionUpdated: Updates a room's description
      # - RoomExitAdded: Adds an exit to a room
      # - RoomExitRemoved: Removes an exit from a room
      class RoomProjector < Sequent::Projector
        manages_tables :rooms
        
        # @param event [RoomCreated] The event to handle
        # Creates a new record in the rooms table for a newly created room.
        # This method is called when a RoomCreated event is processed.
        on RoomCreated do |event|
          create_record(
            :rooms,
            aggregate_id: event.aggregate_id,
            description: event.description,
            exits: Marshal.dump(event.exits || {})
          )
        end
        
        # @param event [RoomDescriptionUpdated] The event to handle
        # Updates a room's description in the rooms table.
        # This method is called when a RoomDescriptionUpdated event is processed.
        on RoomDescriptionUpdated do |event|
          update_all_records(
            :rooms,
            {aggregate_id: event.aggregate_id},
            {description: event.description}
          )
        end
        
        # @param event [RoomExitAdded] The event to handle
        # Adds an exit to a room in the rooms table.
        # This method is called when a RoomExitAdded event is processed.
        on RoomExitAdded do |event|
          update_all_records(
            :rooms,
            {aggregate_id: event.aggregate_id},
            {exits: -> (record) { 
              exits = Marshal.load(record.exits)
              exits[event.direction] = event.target_room_id
              Marshal.dump(exits)
            }}
          )
        end
        
        # @param event [RoomExitRemoved] The event to handle
        # Removes an exit from a room in the rooms table.
        # This method is called when a RoomExitRemoved event is processed.
        on RoomExitRemoved do |event|
          update_all_records(
            :rooms,
            {aggregate_id: event.aggregate_id},
            {exits: -> (record) { 
              exits = Marshal.load(record.exits)
              exits.delete(event.direction)
              Marshal.dump(exits)
            }}
          )
        end
      end
    end
  end
end
