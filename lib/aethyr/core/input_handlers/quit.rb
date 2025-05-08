require "aethyr/core/actions/commands/quit"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

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
            super(player, ["quit"], help_entries: QuitHandler.create_help_entries)
          end
          
          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            case data[:input]
            when /^quit$/i
              $manager.submit_action(Aethyr::Core::Actions::Quit::QuitCommand.new(@player, ))
            end
          end
          
          private
          

        end

        Aethyr::Extend::HandlerRegistry.register_handler(QuitHandler)
      end
    end
  end
end