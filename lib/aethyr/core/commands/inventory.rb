require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Inventory
        class InventoryHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["i", "inv", "inventory"])
          end
          
          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(InventoryHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(i|inv|inventory)$/i
              action({})
            when /^help (i|inv|inventory)$/i
              action_help({})
            end
          end
          
          private
          def action_help(event)
            player.output <<'EOF'
Command: Inventory
Syntax: INVENTORY

Displays what you are holding and wearing.

'i' and 'inv' are shortcuts for inventory.


See also: TAKE, DROP, WEAR, REMOVE
EOF
          end
          
          #Shows the inventory of the player.
          def action(event)
            player.output(player.show_inventory)
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(InventoryHandler)
      end
    end
  end
end