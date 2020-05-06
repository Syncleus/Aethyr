require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Snicker
        class SnickerCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player  "You snicker softly to yourself."
                to_other "You hear #{player.name} snicker softly."
                to_blind_other "You hear someone snicker softly."
              end

              self_target do
                player.output "What are you snickering about?"
              end

              target do
                to_player  "You snicker at #{event.target.name} under your breath."
                to_target "#{player.name} snickers at you under #{player.pronoun(:possessive)} breath."
                to_other "#{player.name} snickers at #{event.target.name} under #{player.pronoun(:possessive)} breath."
              end
            end

          end

        end
      end
    end
  end
end
