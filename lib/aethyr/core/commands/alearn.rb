require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Alearn
        class AlearnHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["alearn"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AlearnHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^alearn\s+(\w+)$/i
              skill = $1
              alearn({:skill => skill})
            when /^help (alearn)$/i
              action_help_alearn({})
            end
          end

          private
          def action_help_alearn(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def alearn(event)

            room = $manager.get_object(@player.container)
            player = @player
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AlearnHandler)
      end
    end
  end
end
