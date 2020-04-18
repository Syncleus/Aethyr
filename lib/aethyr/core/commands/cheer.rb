require "aethyr/core/registry"
require "aethyr/core/commands/emote_handler"

module Aethyr
  module Core
    module Commands
      module Cheer
        class CheerHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["cheer"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(CheerHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(cheer)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              cheer({:object => object, :post => post})
            when /^help (cheer)$/i
              action_help_cheer({})
            end
          end

          private
          def action_help_cheer(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def cheer(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You throw your hands in the air and cheer wildly!"
                to_other "#{player.name} throws #{player.pronoun(:possessive)} hands in the air as #{player.pronoun} cheers wildy!"
                to_blind_other "You hear someone cheering."
              end

              self_target do
                player.output "Hm? How do you do that?"
              end

              target do
                to_player "Beaming at #{event.target.name}, you throw your hands up and cheer for #{event.target.pronoun(:objective)}."
                to_target "Beaming at you, #{player.name} throws #{player.pronoun(:possessive)} hands up and cheers for you."
                to_other "#{player.name} throws #{player.pronoun(:possessive)} hands up and cheers for #{event.target.name}."
                to_blind_other "You hear someone cheering."
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(CheerHandler)
      end
    end
  end
end
