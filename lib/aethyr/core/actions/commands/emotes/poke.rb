require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Poke
        class PokeCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player

            make_emote self, player, room do

              no_target do
                player.output "Who are you trying to poke?"
              end

              self_target do
                to_player  "You poke yourself in the eye. 'Ow!'"
                to_other "#{player.name} pokes #{player.pronoun(:reflexive)} in the eye."
                to_deaf_other self[:to_other]
              end

              target do
                to_player  "You poke #{self.target.name} playfully."
                to_target "#{player.name} pokes you playfully."
                to_blind_target "Someone pokes you playfully."
                to_deaf_target self[:to_target]
                to_other "#{player.name} pokes #{self.target.name} playfully."
                to_deaf_other self[:to_other]
              end
            end
          end

        end
      end
    end
  end
end
