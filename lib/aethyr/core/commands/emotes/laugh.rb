require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Laugh
        class LaughHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["laugh"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(laugh)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              laugh({:object => object, :post => post})
            when /^help (laugh)$/i
              action_help_laugh({})
            end
          end

          private
          def action_help_laugh(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def laugh(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              self_target do
                to_player "You laugh heartily at yourself."
                to_other "#{player.name} laughs heartily at #{player.pronoun(:reflexive)}."
                to_blind_other "Someone laughs heartily."
              end

              target do
                to_player "You laugh at #{event.target.name}."
                to_target "#{player.name} laughs at you."
                to_other "#{player.name} laughs at #{event.target.name}"
                to_blind_target "Someone laughs in your direction."
                to_blind_other "You hear someone laughing."
              end

              no_target do
                to_player "You laugh."
                to_other "#{player.name} laughs."
                to_blind_other "You hear someone laughing."
                to_deaf_other "You see #{player.name} laugh."
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(LaughHandler)
      end
    end
  end
end
