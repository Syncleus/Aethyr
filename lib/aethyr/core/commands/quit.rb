require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Quit
        class QuitHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["quit"])
          end
          
          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(QuitHandler.new(data[:game_object]))
          end

          def player_input(data)
            case data[:input]
            when /^quit$/i
              action({})
            when /^help quit$/i
              action_help({})
            end
          end
          
          private
          def action_help(event)
            player.output <<'EOF'
Command: Quit
Syntax: QUIT

Saves your character and logs you off from the game.

You shouldn't need this too often.

EOF
          end
          
          def action(event)
            $manager.drop_player player
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(QuitHandler)
      end
    end
  end
end