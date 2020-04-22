require "aethyr/core/registry"
require "aethyr/core/commands/emotes/emote_handler"

module Aethyr
  module Core
    module Commands
      module Agree
        class AgreeHandler < Aethyr::Extend::EmoteHandler
          def initialize(player)
            super(player, ["agree"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AgreeHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(agree)( +([^()]*))?( +((.*)))?$/i
              object = $3
              post = $5
              agree({:object => object, :post => post})
            when /^help (agree)$/i
              action_help_agree({})
            end
          end

          private
          def action_help_agree(event)
            @player.output <<'EOF'
Please see help for emote instead.
EOF
          end


          def agree(event)

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You nod your head in agreement."
                to_other "#{player.name} nods #{player.pronoun(:possessive)} head in agreement."
                to_deaf_other event[:to_other]
              end

              self_target do
                to_player "You are in complete agreement with yourself."
                to_other "#{player.name} nods at #{player.pronoun(:reflexive)}, apparently in complete agreement."
                to_deaf_other event[:to_other]
              end

              target do
                to_player "You nod your head in agreement with #{event.target.name}."
                to_target "#{player.name} nods #{player.pronoun(:possessive)} head in agreement with you."
                to_other "#{player.name} nods #{player.pronoun(:possessive)} head in agreement with #{event.target.name}."
                to_deaf_other event[:to_other]
              end
            end

          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AgreeHandler)
      end
    end
  end
end
