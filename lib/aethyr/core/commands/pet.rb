require "aethyr/core/registry"
require "aethyr/core/commands/emote_handler"

module Aethyr
  module Core
    module Commands
      module Pet
        class PetHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["pet"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(PetHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(pet)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              pet({:object => object, :post => post})
            when /^help (pet)$/i
              action_help_pet({})
            end
          end

          private
          def action_help_pet(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def pet(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                player.output "Who are you trying to pet?"
              end

              self_target do
                to_player 'You pet yourself on the head in a calming manner.'
                to_other "#{player.name} pets #{player.pronoun(:reflexive)} on the head in a calming manner."
                to_deaf_other "#{player.name} pets #{player.pronoun(:reflexive)} on the head in a calming manner."
              end

              target do
                to_player "You pet #{event.target.name} affectionately."
                to_target "#{player.name} pets you affectionately."
                to_deaf_target event[:to_target]
                to_blind_target "Someone pets you affectionately."
                to_other "#{player.name} pets #{event.target.name} affectionately."
                to_deaf_other event[:to_other]
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(PetHandler)
      end
    end
  end
end
