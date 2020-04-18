require "aethyr/core/registry"
require "aethyr/core/commands/emote_handler"

module Aethyr
  module Core
    module Commands
      module Uh
        class UhHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["uh"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(UhHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(uh)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              uh({:object => object, :post => post})
            when /^help (uh)$/i
              action_help_uh({})
            end
          end

          private
          def action_help_uh(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def uh(event)

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do
              no_target do
                to_player "\"Uh...\" you say, staring blankly."
                to_other "With a blank stare, #{player.name} says, \"Uh...\""
              end

              target do
                to_player "With a blank stare at #{target.name}, you say, \"Uh...\""
                to_other "With a blank stare at #{target.name}, #{player.name} says, \"Uh...\""
                to_target "Staring blankly at you, #{player.name} says, \"Uh...\""
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(UhHandler)
      end
    end
  end
end
