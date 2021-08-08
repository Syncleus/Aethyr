require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Agree
        class AgreeCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]

            make_emote event, player, room do

              no_target do
                to_player "You nod your head in agreement."
                to_other "#{player.name} nods #{player.pronoun(:possessive)} head in agreement."
                to_deaf_other self[:to_other]
              end

              self_target do
                to_player "You are in complete agreement with yourself."
                to_other "#{player.name} nods at #{player.pronoun(:reflexive)}, apparently in complete agreement."
                to_deaf_other self[:to_other]
              end

              target do
                to_player "You nod your head in agreement with #{event.target.name}."
                to_target "#{player.name} nods #{player.pronoun(:possessive)} head in agreement with you."
                to_other "#{player.name} nods #{player.pronoun(:possessive)} head in agreement with #{event.target.name}."
                to_deaf_other self[:to_other]
              end
            end

          end

        end
      end
    end
  end
end
