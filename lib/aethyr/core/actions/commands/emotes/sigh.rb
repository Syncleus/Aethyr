require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Sigh
        class SighCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]

            make_emote event, player, room do

              no_target do
                to_player "You exhale, sighing deeply."
                to_other "#{player.name} breathes out a deep sigh."
              end

              self_target do
                to_player "You sigh at your misfortunes."
                to_other "#{player.name} sighs at #{player.pronoun(:possessive)} own misfortunes."
              end

              target do
                to_player "You sigh in #{event.target.name}'s general direction."
                to_target "#{player.name} heaves a sigh in your direction."
                to_other "#{player.name} sighs heavily in #{event.target.name}'s direction."
              end
            end

          end

        end
      end
    end
  end
end
