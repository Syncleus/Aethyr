require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Blush
        class BlushCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]

            make_emote event, player, room do

              no_target do
                to_player "You feel the blood rush to your cheeks and you look down, blushing."
                to_other "#{player.name}'s face turns bright red as #{player.pronoun} looks down, blushing."
                to_deaf_other self[:to_other]
              end

              self_target do
                to_player "You blush at your foolishness."
                to_other "#{player.name} blushes at #{event.target.pronoun(:possessive)} foolishness."
                to_deaf_other self[:to_other]
              end

              target do
                to_player "Your face turns red and you blush at #{event.target.name} uncomfortably."
                to_target "#{player.name} blushes in your direction."
                to_deaf_target self[:to_target]
                to_other "#{player.name} blushes at #{event.target.name}, clearly uncomfortable."
                to_deaf_other self[:to_other]
              end
            end
          end

        end
      end
    end
  end
end
