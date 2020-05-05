require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Pet
        class PetCommand < Aethyr::Core::Actions::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

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
      end
    end
  end
end
