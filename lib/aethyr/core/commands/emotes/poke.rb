require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Poke
        class PokeHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["poke"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(PokeHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(poke)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              poke({:object => object, :post => post})
            when /^help (poke)$/i
              action_help_poke({})
            end
          end

          private
          def action_help_poke(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def poke(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                player.output "Who are you trying to poke?"
              end

              self_target do
                to_player  "You poke yourself in the eye. 'Ow!'"
                to_other "#{player.name} pokes #{player.pronoun(:reflexive)} in the eye."
                to_deaf_other event[:to_other]
              end

              target do
                to_player  "You poke #{event.target.name} playfully."
                to_target "#{player.name} pokes you playfully."
                to_blind_target "Someone pokes you playfully."
                to_deaf_target event[:to_target]
                to_other "#{player.name} pokes #{event.target.name} playfully."
                to_deaf_other event[:to_other]
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(PokeHandler)
      end
    end
  end
end
