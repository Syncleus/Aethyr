require "aethyr/core/actions/commands/drop"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Drop
        class DropHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "drop"
            see_also = ["GET", "TAKE", "GRAB"]
            syntax_formats = ["DROP [object]"]
            aliases = nil
            content =  <<'EOF'
Removes an object from your inventory and places it gently on the ground.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["drop"], help_entries: DropHandler.create_help_entries)
          end
          
          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^drop\s+((\w+\s*)*)$/i
              $manager.submit_action(Aethyr::Core::Actions::Drop::DropCommand.new(@player, { :object => $1.strip }))
            end
          end
          
          private
          #Drops an item from the player's inventory into the room.

        end

        Aethyr::Extend::HandlerRegistry.register_handler(DropHandler)
      end
    end
  end
end