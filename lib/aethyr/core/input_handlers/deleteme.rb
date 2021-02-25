
require "aethyr/core/actions/commands/deleteme"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Deleteme
        class DeletemeHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "deleteme"
            see_also = nil
            syntax_formats = ["DELETE ME PLEASE"]
            aliases = nil
            content =  <<'EOF'
Deleting Your Character

In case you ever need to do so, you can remove your character from the game. Quite permanently. You will need to enter your password as confirmation and that's it. You will be wiped out of time and memory.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["delete"], help_entries: DeletemeHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^delete me please$/i
              $manager.submit_action(Aethyr::Core::Actions::Deleteme::DeletemeCommand.new(@player, {}))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(DeletemeHandler)
      end
    end
  end
end
