require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Frown
        class FrownHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["frown"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(frown)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              frown({:object => object, :post => post})
            when /^help (frown)$/i
              action_help_frown({})
            end
          end

          private
          def action_help_frown(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def frown(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do
              no_target do
                to_player "The edges of your mouth turn down as you frown."
                to_other "The edges of #{player.name}'s mouth turn down as #{player.pronoun} frowns."
                to_deaf_other event[:to_other]
              end

              self_target do
                to_player "You frown sadly at yourself."
                to_other "#{player.name} frowns sadly at #{event.target.pronoun(:reflexive)}."
                to_deaf_other event[:to_other]
              end

              target do
                to_player "You frown at #{event.target.name} unhappily."
                to_target "#{player.name} frowns at you unhappily."
                to_deaf_target event[:to_target]
                to_other "#{player.name} frowns at #{event.target.name} unhappily."
                to_deaf_other event[:to_other]
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(FrownHandler)
      end
    end
  end
end
