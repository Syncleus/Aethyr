require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Yawn
        class YawnCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]

            make_emote event, player, room do

              no_target do
                to_player "You open your mouth in a wide yawn, then exhale loudly."
                to_other "#{player.name} opens #{player.pronoun(:possessive)} mouth in a wide yawn, then exhales loudly."
              end

              self_target do
                to_player "You yawn at how boring you are."
                to_other "#{player.name} yawns at #{player.pronoun(:reflexive)}."
                to_deaf_other self[:to_other]
              end

              target do
                to_player "You yawn at #{event.target.name}, bored out of your mind."
                to_target "#{player.name} yawns at you, finding you boring."
                to_other "#{player.name} yawns at how boring #{event.target.name} is."
                to_deaf_other self[:to_other]
              end
            end

          end

        end
      end
    end
  end
end
