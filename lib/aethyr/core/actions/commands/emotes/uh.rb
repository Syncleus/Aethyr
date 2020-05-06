require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Uh
        class UhCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do
              no_target do
                to_player "\"Uh...\" you say, staring blankly."
                to_other "With a blank stare, #{player.name} says, \"Uh...\""
              end

              target do
                to_player "With a blank stare at #{target.name}, you say, \"Uh...\""
                to_other "With a blank stare at #{target.name}, #{player.name} says, \"Uh...\""
                to_target "Staring blankly at you, #{player.name} says, \"Uh...\""
              end
            end
          end

        end
      end
    end
  end
end
