require 'sequent'

module Aethyr
  module Core
    module EventSourcing
      # Command to create a new game object in the system.
      # This command contains all the information needed to create a new game object,
      # including its ID, name, generic type, and container.
      #
      # @attr id [String] The unique identifier for the new game object
      # @attr name [String] The name of the game object
      # @attr generic [String] The generic type of the game object (e.g., "sword", "potion")
      # @attr container_id [String] The ID of the container that will hold this object
      class CreateGameObject < Sequent::Command
        attrs id: String, name: String, generic: String, container_id: String
        validates :id, :name, presence: true
      end
      
      # Command to update a single attribute of a game object.
      # This command contains the ID of the game object to update,
      # the name of the attribute to update, and the new value for the attribute.
      #
      # @attr id [String] The ID of the game object to update
      # @attr key [String] The name of the attribute to update
      # @attr value [Object] The new value for the attribute
      class UpdateGameObjectAttribute < Sequent::Command
        attrs id: String, key: String, value: Object
        validates :id, :key, presence: true
      end
      
      # Command to update multiple attributes of a game object at once.
      # This command contains the ID of the game object to update and
      # a hash mapping attribute names to their new values.
      #
      # @attr id [String] The ID of the game object to update
      # @attr attributes [Hash] A hash mapping attribute names to their new values
      class UpdateGameObjectAttributes < Sequent::Command
        attrs id: String, attributes: Hash
        validates :id, :attributes, presence: true
      end
      
      # Command to move a game object to a new container.
      # This command contains the ID of the game object to move and
      # the ID of the new container.
      #
      # @attr id [String] The ID of the game object to move
      # @attr container_id [String] The ID of the new container
      class UpdateGameObjectContainer < Sequent::Command
        attrs id: String, container_id: String
        validates :id, :container_id, presence: true
      end
      
      # Command to delete a game object from the system.
      # This command contains the ID of the game object to delete.
      #
      # @attr id [String] The ID of the game object to delete
      class DeleteGameObject < Sequent::Command
        attrs id: String
        validates :id, presence: true
      end
      
      # Command to create a new player in the system.
      # This command contains all the information needed to create a new player,
      # including their ID, name, and password hash.
      #
      # @attr id [String] The unique identifier for the new player
      # @attr name [String] The player's name
      # @attr password_hash [String] The hashed password for the player
      class CreatePlayer < Sequent::Command
        attrs id: String, name: String, password_hash: String
        validates :id, :name, :password_hash, presence: true
      end
      
      # Command to update a player's password.
      # This command contains the ID of the player to update and
      # the new password hash.
      #
      # @attr id [String] The ID of the player to update
      # @attr password_hash [String] The new hashed password
      class UpdatePlayerPassword < Sequent::Command
        attrs id: String, password_hash: String
        validates :id, :password_hash, presence: true
      end
      
      # Command to update a player's admin status.
      # This command contains the ID of the player to update and
      # a boolean indicating whether they should have admin privileges.
      #
      # @attr id [String] The ID of the player to update
      # @attr admin [Boolean] Whether the player should have admin privileges
      class UpdatePlayerAdminStatus < Sequent::Command
        attrs id: String, admin: Boolean
        validates :id, presence: true
      end
      
      # Command to create a new room in the system.
      # This command contains all the information needed to create a new room,
      # including its ID, name, and description.
      #
      # @attr id [String] The unique identifier for the new room
      # @attr name [String] The name of the room
      # @attr description [String] The description of the room
      class CreateRoom < Sequent::Command
        attrs id: String, name: String, description: String
        validates :id, :name, presence: true
      end
      
      # Command to update a room's description.
      # This command contains the ID of the room to update and
      # the new description.
      #
      # @attr id [String] The ID of the room to update
      # @attr description [String] The new description for the room
      class UpdateRoomDescription < Sequent::Command
        attrs id: String, description: String
        validates :id, :description, presence: true
      end
      
      # Command to add an exit to a room.
      # This command contains the ID of the room to add the exit to,
      # the direction of the exit, and the ID of the room the exit leads to.
      #
      # @attr id [String] The ID of the room to add the exit to
      # @attr direction [String] The direction of the exit (e.g., "north", "south")
      # @attr target_room_id [String] The ID of the room the exit leads to
      class AddRoomExit < Sequent::Command
        attrs id: String, direction: String, target_room_id: String
        validates :id, :direction, :target_room_id, presence: true
      end
      
      # Command to remove an exit from a room.
      # This command contains the ID of the room to remove the exit from and
      # the direction of the exit to remove.
      #
      # @attr id [String] The ID of the room to remove the exit from
      # @attr direction [String] The direction of the exit to remove
      class RemoveRoomExit < Sequent::Command
        attrs id: String, direction: String
        validates :id, :direction, presence: true
      end
      
      # Command to add an item to an inventory.
      # This command contains the ID of the inventory owner,
      # the ID of the item to add, and optionally the position in the inventory.
      #
      # @attr id [String] The ID of the inventory owner
      # @attr item_id [String] The ID of the item to add
      # @attr position [Object] The position in the inventory (optional)
      class AddItemToInventory < Sequent::Command
        attrs id: String, item_id: String, position: Object
        validates :id, :item_id, presence: true
      end
      
      # Command to remove an item from an inventory.
      # This command contains the ID of the inventory owner and
      # the ID of the item to remove.
      #
      # @attr id [String] The ID of the inventory owner
      # @attr item_id [String] The ID of the item to remove
      class RemoveItemFromInventory < Sequent::Command
        attrs id: String, item_id: String
        validates :id, :item_id, presence: true
      end
      
      # Command to equip an item.
      # This command contains the ID of the character,
      # the ID of the item to equip, and the equipment slot to use.
      #
      # @attr id [String] The ID of the character
      # @attr item_id [String] The ID of the item to equip
      # @attr slot [String] The equipment slot to use (e.g., "head", "hands")
      class EquipItem < Sequent::Command
        attrs id: String, item_id: String, slot: String
        validates :id, :item_id, :slot, presence: true
      end
      
      # Command to unequip an item.
      # This command contains the ID of the character,
      # the ID of the item to unequip, and the equipment slot the item is in.
      #
      # @attr id [String] The ID of the character
      # @attr item_id [String] The ID of the item to unequip
      # @attr slot [String] The equipment slot the item is in
      class UnequipItem < Sequent::Command
        attrs id: String, item_id: String, slot: String
        validates :id, :item_id, :slot, presence: true
      end
    end
  end
end
