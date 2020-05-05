require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Cry
        class CryCommand < Aethyr::Core::Actions::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              default do
                to_player "Tears run down your face as you cry pitifully."
                to_other "Tears run down #{player.name}'s face as #{player.pronoun} cries pitifully."
              end
            end
          end

        end
      end
    end
  end
end
