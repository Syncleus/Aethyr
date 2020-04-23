require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Back
        class BackHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["back"])
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(back)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              back({:object => object, :post => post})
            when /^help (back)$/i
              action_help_back({})
            end
          end

          private
          def action_help_back(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def back(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "\"I'm back!\" you happily announce."
                to_other "\"I'm back!\" #{player.name} happily announces to those nearby."
                to_blind_other "Someone announces, \"I'm back!\""
              end

              self_target do
                player.output "Hm? How do you do that?"
              end

              target do
                to_player "You happily announce your return to #{event.target.name}."
                to_target "#{player.name} happily announces #{player.pronoun(:possessive)} return to you."
                to_other "#{player.name} announces #{player.pronoun(:possessive)} return to #{event.target.name}."
                to_blind_other "Someone says, \"I shall return shortly!\""
              end
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(BackHandler)
      end
    end
  end
end
