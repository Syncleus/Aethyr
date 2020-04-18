require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Restart
        class RestartHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["restart"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(RestartHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^restart$/i
              restart({})
            when /^help (restart)$/i
              action_help_restart({})
            end
          end

          private
          def action_help_restart(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def restart(event)

            room = $manager.get_object(@player.container)
            player = @player
            $manager.restart
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(RestartHandler)
      end
    end
  end
end
