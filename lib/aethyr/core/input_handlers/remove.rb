require "aethyr/core/actions/commands/remove"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Remove
        class RemoveHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "remove"
            see_also = ["WEAR", "INVENTORY"]
            syntax_formats = ["REMOVE <object>"]
            aliases = nil
            content =  <<'EOF'
Remove an article of clothing or armor.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["remove"], help_entries: RemoveHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^remove\s+(\w+)(\s+from\s+(.*))?$/i
              object = $1
              position = $3
              $manager.submit_action(Aethyr::Core::Actions::Remove::RemoveCommand.new(@player, :object => object, :position => position))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(RemoveHandler)
      end
    end
  end
end
