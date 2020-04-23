require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Drop
        class DropHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["drop"])
          end
          
          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^drop\s+((\w+\s*)*)$/i
              action({ :object => $1.strip })
            when /^help drop$/i
              action_help({})
            end
          end
          
          private
          #Drops an item from the player's inventory into the room.
          def action(event)
            room = $manager.get_object(@player.container)
            object = @player.inventory.find(event[:object])

            if object.nil?
              if response = @player.equipment.worn_or_wielded?(event[:object])
                @player.output response
              else
                @player.output "You have no #{event[:object]} to drop."
              end

              return
            end

            @player.inventory.remove(object)

            object.container = room.goid
            room.add(object)

            event[:to_player] = "You drop #{object.name}."
            event[:to_other] = "#{@player.name} drops #{object.name}."
            event[:to_blind_other] = "You hear something hit the ground."
            room.out_event(event)
          end
          
          def action_help(event)
            @player.output <<'EOF'
Command: Drop
Syntax: DROP [object]

Removes an object from your inventory and places it gently on the ground.

See also: GET, TAKE, GRAB

EOF
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(DropHandler)
      end
    end
  end
end