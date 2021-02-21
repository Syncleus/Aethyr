require "aethyr/core/actions/commands/inventory"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Inventory
        class InventoryHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "inventory"
            see_also = ["TAKE", "DROP", "WEAR", "REMOVE"]
            syntax_formats = ["INVENTORY"]
            aliases = ["i", "inv"]
            content =  <<'EOF'
Displays what you are holding and wearing.

'i' and 'inv' are shortcuts for inventory.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["i", "inv", "inventory"], help_entries: InventoryHandler.create_help_entries)
          end
          
          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(i|inv|inventory)$/i
              $manager.submit_action(Aethyr::Core::Actions::Inventory::InventoryCommand.new(@player, {}))
            end
          end
          
          private
          
          #Shows the inventory of the player.

        end

        Aethyr::Extend::HandlerRegistry.register_handler(InventoryHandler)
      end
    end
  end
end