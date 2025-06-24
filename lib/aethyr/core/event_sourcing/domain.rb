require 'sequent'
require 'aethyr/core/util/guid'
require 'aethyr/core/event_sourcing/events'

module Aethyr
  module Core
    module EventSourcing
      # The Domain module contains all aggregate root classes used in the event sourcing system.
      # These classes represent the core domain models of the game and encapsulate the business logic
      # for handling commands and applying events.
      #
      # Each aggregate root is responsible for maintaining its own state and ensuring that
      # state changes are only made through events. This ensures that all state changes
      # are properly recorded and can be replayed to reconstruct the aggregate's state.
      #
      # The module includes the following aggregate roots:
      # - GameObject: Base aggregate for all game objects
      # - Player: Player-specific aggregate with authentication and admin capabilities
      # - Room: Room-specific aggregate with exits and description management
      module Domain
        # Base aggregate root for all game objects in the Aethyr world.
        # This class provides the foundation for all persistent entities in the game,
        # handling common attributes and behaviors shared by all game objects.
        #
        # The GameObject aggregate maintains the following state:
        # - name: The display name of the object
        # - generic: The generic type of the object (e.g., "sword", "potion")
        # - container_id: The ID of the container holding this object
        # - attributes: A hash of additional attributes for the object
        # - deleted: A flag indicating whether the object has been deleted
        #
        # All state changes are made through events, ensuring a complete audit trail
        # and enabling temporal queries and replays.
        #
        # @example Creating a new game object
        #   sword = GameObject.new("obj-123", "Excalibur", "sword", "room-456")
        #
        # @example Updating an attribute
        #   sword.update_attribute("damage", 10)
        #
        # @example Moving to a new container
        #   sword.update_container("player-789")
        class GameObject < Sequent::AggregateRoot
          attr_reader :name, :generic, :container_id, :attributes
          
          def initialize(id, name, generic, container_id = nil)
            super(id)
            apply GameObjectCreated, name: name, generic: generic, container_id: container_id, attributes: {}
          end
          
          # Command handlers
          def update_attribute(key, value)
            apply GameObjectAttributeUpdated, key: key, value: value
          end
          
          def update_attributes(attributes)
            apply GameObjectAttributesUpdated, attributes: attributes
          end
          
          def update_container(container_id)
            apply GameObjectContainerUpdated, container_id: container_id
          end
          
          def delete
            apply GameObjectDeleted
          end
          
          # Event handlers
          on GameObjectCreated do |event|
            @name = event.name
            @generic = event.generic
            @container_id = event.container_id
            @attributes = event.attributes || {}
            @deleted = false
          end
          
          on GameObjectAttributeUpdated do |event|
            @attributes[event.key] = event.value
          end
          
          on GameObjectAttributesUpdated do |event|
            event.attributes.each do |key, value|
              @attributes[key] = value
            end
          end
          
          on GameObjectContainerUpdated do |event|
            @container_id = event.container_id
          end
          
          on GameObjectDeleted do |_|
            @deleted = true
          end
          
          def deleted?
            @deleted
          end
        end
        
        # Player-specific aggregate root representing a player character in the game.
        # This class extends the GameObject aggregate with player-specific attributes
        # and behaviors, such as password management and admin status.
        #
        # The Player aggregate maintains the following additional state beyond GameObject:
        # - password_hash: The hashed password for authentication
        # - admin: A flag indicating whether the player has admin privileges
        #
        # All state changes are made through events, ensuring a complete audit trail
        # and enabling temporal queries and replays.
        #
        # @example Creating a new player
        #   player = Player.new("player-123", "Gandalf", "5f4dcc3b5aa765d61d8327deb882cf99")
        #
        # @example Setting admin status
        #   player.set_admin(true)
        #
        # @example Changing password
        #   player.set_password("new_password_hash")
        class Player < GameObject
          attr_reader :password_hash, :admin
          
          def initialize(id, name, password_hash)
            super(id, name, "player")
            apply PlayerCreated, password_hash: password_hash, admin: false
          end
          
          def set_password(password_hash)
            apply PlayerPasswordUpdated, password_hash: password_hash
          end
          
          def set_admin(admin)
            apply PlayerAdminStatusUpdated, admin: admin
          end
          
          # Event handlers
          on PlayerCreated do |event|
            @password_hash = event.password_hash
            @admin = event.admin
          end
          
          on PlayerPasswordUpdated do |event|
            @password_hash = event.password_hash
          end
          
          on PlayerAdminStatusUpdated do |event|
            @admin = event.admin
          end
        end
        
        # Room-specific aggregate root representing a location in the game world.
        # This class extends the GameObject aggregate with room-specific attributes
        # and behaviors, such as description management and exit connections.
        #
        # The Room aggregate maintains the following additional state beyond GameObject:
        # - description: A detailed description of the room
        # - exits: A hash mapping directions to target room IDs
        #
        # All state changes are made through events, ensuring a complete audit trail
        # and enabling temporal queries and replays.
        #
        # @example Creating a new room
        #   room = Room.new("room-123", "Forest Clearing", "A peaceful clearing in the forest.")
        #
        # @example Adding an exit
        #   room.add_exit("north", "room-456")
        #
        # @example Updating the description
        #   room.update_description("A sunlit clearing surrounded by ancient trees.")
        class Room < GameObject
          attr_reader :description, :exits
          
          def initialize(id, name, description)
            super(id, name, "room")
            apply RoomCreated, description: description, exits: {}
          end
          
          def update_description(description)
            apply RoomDescriptionUpdated, description: description
          end
          
          def add_exit(direction, target_room_id)
            apply RoomExitAdded, direction: direction, target_room_id: target_room_id
          end
          
          def remove_exit(direction)
            apply RoomExitRemoved, direction: direction
          end
          
          # Event handlers
          on RoomCreated do |event|
            @description = event.description
            @exits = event.exits || {}
          end
          
          on RoomDescriptionUpdated do |event|
            @description = event.description
          end
          
          on RoomExitAdded do |event|
            @exits[event.direction] = event.target_room_id
          end
          
          on RoomExitRemoved do |event|
            @exits.delete(event.direction)
          end
        end
      end
    end
  end
end
