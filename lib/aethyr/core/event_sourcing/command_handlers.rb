require 'sequent'
require 'aethyr/core/event_sourcing/domain'
require 'aethyr/core/event_sourcing/commands'

module Aethyr
  module Core
    module EventSourcing
      # Command handler for game object commands.
      #
      # This class processes commands related to game objects, players, and rooms,
      # delegating to the appropriate aggregate methods to apply events.
      # It serves as the entry point for all command processing in the event sourcing system.
      #
      # The command handler is responsible for:
      # - Loading the appropriate aggregate from the repository
      # - Executing the command on the aggregate
      # - Saving the updated aggregate back to the repository
      #
      # Each command type has a dedicated handler method that knows how to process
      # that specific command and apply the appropriate events to the aggregate.
      class GameObjectCommandHandler < Sequent::CommandHandler
        # Handles the CreateGameObject command.
        #
        # This method creates a new GameObject aggregate and adds it to the repository.
        # It is called when a CreateGameObject command is received.
        #
        # @param command [CreateGameObject] The command to handle
        # @return [void]
        on CreateGameObject do |command|
          repository.add_aggregate(Domain::GameObject.new(command.id, command.name, command.generic, command.container_id))
        end
        
        # Handles the UpdateGameObjectAttribute command.
        #
        # This method updates a single attribute of a GameObject aggregate.
        # It is called when an UpdateGameObjectAttribute command is received.
        #
        # @param command [UpdateGameObjectAttribute] The command to handle
        # @return [void]
        on UpdateGameObjectAttribute do |command|
          do_with_aggregate(command.id, Domain::GameObject) do |game_object|
            game_object.update_attribute(command.key, command.value)
          end
        end
        
        # Handles the UpdateGameObjectAttributes command.
        #
        # This method updates multiple attributes of a GameObject aggregate.
        # It is called when an UpdateGameObjectAttributes command is received.
        #
        # @param command [UpdateGameObjectAttributes] The command to handle
        # @return [void]
        on UpdateGameObjectAttributes do |command|
          do_with_aggregate(command.id, Domain::GameObject) do |game_object|
            game_object.update_attributes(command.attributes)
          end
        end
        
        # Handles the UpdateGameObjectContainer command.
        #
        # This method updates the container of a GameObject aggregate.
        # It is called when an UpdateGameObjectContainer command is received.
        #
        # @param command [UpdateGameObjectContainer] The command to handle
        # @return [void]
        on UpdateGameObjectContainer do |command|
          do_with_aggregate(command.id, Domain::GameObject) do |game_object|
            game_object.update_container(command.container_id)
          end
        end
        
        # Handles the DeleteGameObject command.
        #
        # This method marks a GameObject aggregate as deleted.
        # It is called when a DeleteGameObject command is received.
        #
        # @param command [DeleteGameObject] The command to handle
        # @return [void]
        on DeleteGameObject do |command|
          do_with_aggregate(command.id, Domain::GameObject) do |game_object|
            game_object.delete
          end
        end
        
        # Handles the CreatePlayer command.
        #
        # This method creates a new Player aggregate and adds it to the repository.
        # It is called when a CreatePlayer command is received.
        #
        # @param command [CreatePlayer] The command to handle
        # @return [void]
        on CreatePlayer do |command|
          repository.add_aggregate(Domain::Player.new(command.id, command.name, command.password_hash))
        end
        
        # Handles the UpdatePlayerPassword command.
        #
        # This method updates the password of a Player aggregate.
        # It is called when an UpdatePlayerPassword command is received.
        #
        # @param command [UpdatePlayerPassword] The command to handle
        # @return [void]
        on UpdatePlayerPassword do |command|
          do_with_aggregate(command.id, Domain::Player) do |player|
            player.set_password(command.password_hash)
          end
        end
        
        # Handles the UpdatePlayerAdminStatus command.
        #
        # This method updates the admin status of a Player aggregate.
        # It is called when an UpdatePlayerAdminStatus command is received.
        #
        # @param command [UpdatePlayerAdminStatus] The command to handle
        # @return [void]
        on UpdatePlayerAdminStatus do |command|
          do_with_aggregate(command.id, Domain::Player) do |player|
            player.set_admin(command.admin)
          end
        end
        
        # Handles the CreateRoom command.
        #
        # This method creates a new Room aggregate and adds it to the repository.
        # It is called when a CreateRoom command is received.
        #
        # @param command [CreateRoom] The command to handle
        # @return [void]
        on CreateRoom do |command|
          repository.add_aggregate(Domain::Room.new(command.id, command.name, command.description))
        end
        
        # Handles the UpdateRoomDescription command.
        #
        # This method updates the description of a Room aggregate.
        # It is called when an UpdateRoomDescription command is received.
        #
        # @param command [UpdateRoomDescription] The command to handle
        # @return [void]
        on UpdateRoomDescription do |command|
          do_with_aggregate(command.id, Domain::Room) do |room|
            room.update_description(command.description)
          end
        end
        
        # Handles the AddRoomExit command.
        #
        # This method adds an exit to a Room aggregate.
        # It is called when an AddRoomExit command is received.
        #
        # @param command [AddRoomExit] The command to handle
        # @return [void]
        on AddRoomExit do |command|
          do_with_aggregate(command.id, Domain::Room) do |room|
            room.add_exit(command.direction, command.target_room_id)
          end
        end
        
        # Handles the RemoveRoomExit command.
        #
        # This method removes an exit from a Room aggregate.
        # It is called when a RemoveRoomExit command is received.
        #
        # @param command [RemoveRoomExit] The command to handle
        # @return [void]
        on RemoveRoomExit do |command|
          do_with_aggregate(command.id, Domain::Room) do |room|
            room.remove_exit(command.direction)
          end
        end
      end
    end
  end
end
