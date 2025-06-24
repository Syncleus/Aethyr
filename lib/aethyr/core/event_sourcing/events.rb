require 'sequent'

module Aethyr
  module Core
    # @author Aethyr Development Team
    # @since 1.0.0
    #
    # The EventSourcing module contains all classes and functionality related to
    # the event sourcing system within the Core module. This includes events,
    # commands, command handlers, domain models, and projections.
    module EventSourcing
      # @author Aethyr Development Team
      # @since 1.0.0
      #
      # Event indicating that a new game object has been created.
      # This event captures the initial state of a game object, including its
      # name, generic type, container, and any initial attributes.
      #
      # @attr name [String] The name of the created game object
      # @attr generic [String] The generic type of the game object (e.g., "sword", "potion")
      # @attr container_id [String] The ID of the container holding this object
      # @attr attributes [Hash] Additional attributes for the game object
      class GameObjectCreated < Sequent::Event
        attrs name: String, generic: String, container_id: String, attributes: Hash
      end
      
      # Event indicating that an attribute of a game object has been updated.
      # This event captures a change to a single attribute of a game object.
      #
      # @attr key [String] The name of the updated attribute
      # @attr value [Object] The new value of the attribute
      class GameObjectAttributeUpdated < Sequent::Event
        attrs key: String, value: Object
      end
      
      # Event indicating that multiple attributes of a game object have been updated.
      # This event captures changes to multiple attributes of a game object in a single operation.
      #
      # @attr attributes [Hash] A hash mapping attribute names to their new values
      class GameObjectAttributesUpdated < Sequent::Event
        attrs attributes: Hash
      end
      
      # Event indicating that a game object has been moved to a new container.
      # This event captures a change in the location or ownership of a game object.
      #
      # @attr container_id [String] The ID of the new container
      class GameObjectContainerUpdated < Sequent::Event
        attrs container_id: String
      end
      
      # Event indicating that a game object has been deleted.
      # This event marks a game object as deleted, which means it should no longer
      # be accessible in the game world.
      class GameObjectDeleted < Sequent::Event
      end
      
      # Event indicating that a new player has been created.
      # This event captures player-specific information beyond the basic game object
      # attributes, such as password hash and admin status.
      #
      # @attr password_hash [String] The hashed password for the player
      # @attr admin [Boolean] Whether the player has admin privileges
      class PlayerCreated < Sequent::Event
        attrs password_hash: String, admin: Boolean
      end
      
      # Event indicating that a player's password has been updated.
      # This event captures a change to a player's password hash.
      #
      # @attr password_hash [String] The new hashed password
      class PlayerPasswordUpdated < Sequent::Event
        attrs password_hash: String
      end
      
      # Event indicating that a player's admin status has been updated.
      # This event captures a change to a player's administrative privileges.
      #
      # @attr admin [Boolean] The new admin status
      class PlayerAdminStatusUpdated < Sequent::Event
        attrs admin: Boolean
      end
      
      # Event indicating that a new room has been created.
      # This event captures room-specific information beyond the basic game object
      # attributes, such as description and exits.
      #
      # @attr description [String] The description of the room
      # @attr exits [Hash] A hash mapping directions to target room IDs
      class RoomCreated < Sequent::Event
        attrs description: String, exits: Hash
      end
      
      # Event indicating that a room's description has been updated.
      # This event captures a change to a room's description.
      #
      # @attr description [String] The new description
      class RoomDescriptionUpdated < Sequent::Event
        attrs description: String
      end
      
      # Event indicating that an exit has been added to a room.
      # This event captures the addition of a new exit from a room to another room.
      #
      # @attr direction [String] The direction of the exit (e.g., "north", "south")
      # @attr target_room_id [String] The ID of the room the exit leads to
      class RoomExitAdded < Sequent::Event
        attrs direction: String, target_room_id: String
      end
      
      # Event indicating that an exit has been removed from a room.
      # This event captures the removal of an exit from a room.
      #
      # @attr direction [String] The direction of the removed exit
      class RoomExitRemoved < Sequent::Event
        attrs direction: String
      end
      
      # Event indicating that an item has been added to an inventory.
      # This event captures the addition of an item to a container's inventory.
      #
      # @attr item_id [String] The ID of the added item
      # @attr position [Object] The position in the inventory (optional)
      class ItemAddedToInventory < Sequent::Event
        attrs item_id: String, position: Object
      end
      
      # Event indicating that an item has been removed from an inventory.
      # This event captures the removal of an item from a container's inventory.
      #
      # @attr item_id [String] The ID of the removed item
      class ItemRemovedFromInventory < Sequent::Event
        attrs item_id: String
      end
      
      # Event indicating that an item has been equipped.
      # This event captures the equipping of an item by a character.
      #
      # @attr item_id [String] The ID of the equipped item
      # @attr slot [String] The equipment slot used (e.g., "head", "hands")
      class ItemEquipped < Sequent::Event
        attrs item_id: String, slot: String
      end
      
      # Event indicating that an item has been unequipped.
      # This event captures the unequipping of an item by a character.
      #
      # @attr item_id [String] The ID of the unequipped item
      # @attr slot [String] The equipment slot the item was in
      class ItemUnequipped < Sequent::Event
        attrs item_id: String, slot: String
      end
    end
  end
end
