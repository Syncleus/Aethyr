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
            

            room = $manager.get_object(@player.container)
            player = @player

            make_emote self, player, room do

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
                to_player "You yawn at #{self.target.name}, bored out of your mind."
                to_target "#{player.name} yawns at you, finding you boring."
                to_other "#{player.name} yawns at how boring #{self.target.name} is."
                to_deaf_other self[:to_other]
              end
            end

          end

        end
      end
    end
  end
end
