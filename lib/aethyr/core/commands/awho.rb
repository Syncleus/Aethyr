require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Awho
        class AwhoHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["awho"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AwhoHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^awho/i
              awho({})
            when /^help (awho)$/i
              action_help_awho({})
            end
          end

          private
          def action_help_awho(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def awho(event)

            room = $manager.get_object(@player.container)
            player = @player
            players = $manager.find_all('class', Player)

            names = []
            players.each do |playa|
              names << playa.name
            end

            player.output('Players currently online:', true)
            player.output(names.join(', '))
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AwhoHandler)
      end
    end
  end
end
