require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Nod
        class NodCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player

            make_emote self, player, room do

              no_target do
                to_player "You nod your head."
                to_other "#{player.name} nods #{player.pronoun(:possessive)} head."
                to_deaf_other self[:to_other]
              end

              self_target do
                to_player 'You nod to yourself thoughtfully.'
                to_other "#{player.name} nods to #{player.pronoun(:reflexive)} thoughtfully."
                to_deaf_other self[:to_other]
              end

              target do

                to_player "You nod your head towards #{self.target.name}."
                to_target "#{player.name} nods #{player.pronoun(:possessive)} head towards you."
                to_other "#{player.name} nods #{player.pronoun(:possessive)} head towards #{self.target.name}."
                to_deaf_other self[:to_other]
              end
            end
          end

        end
      end
    end
  end
end
