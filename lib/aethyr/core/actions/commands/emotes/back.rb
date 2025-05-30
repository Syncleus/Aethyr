require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Back
        class BackCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player

            make_emote self, player, room do

              no_target do
                to_player "\"I'm back!\" you happily announce."
                to_other "\"I'm back!\" #{player.name} happily announces to those nearby."
                to_blind_other "Someone announces, \"I'm back!\""
              end

              self_target do
                player.output "Hm? How do you do that?"
              end

              target do
                to_player "You happily announce your return to #{self.target.name}."
                to_target "#{player.name} happily announces #{player.pronoun(:possessive)} return to you."
                to_other "#{player.name} announces #{player.pronoun(:possessive)} return to #{self.target.name}."
                to_blind_other "Someone says, \"I shall return shortly!\""
              end
            end
          end

        end
      end
    end
  end
end
