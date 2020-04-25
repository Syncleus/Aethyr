require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Quit
        class QuitHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "quit"
            see_also = nil
            syntax_formats = ["QUIT"]
            aliases = nil
            content =  <<'EOF'
Saves your character and logs you off from the game.

You shouldn't need this too often.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["quit"], QuitHandler.create_help_entries)
          end
          
          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            case data[:input]
            when /^quit$/i
              action({})
            end
          end
          
          private
          
          def action(event)
            $manager.drop_player player
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(QuitHandler)
      end
    end
  end
end