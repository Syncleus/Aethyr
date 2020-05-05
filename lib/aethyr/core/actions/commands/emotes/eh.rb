require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Eh
        class EhCommand < Aethyr::Core::Actions::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do
              target do
                to_player "After giving #{event.target.name} a cursory glance, you emit an unimpressed, 'Eh.'"
                to_other "#{player.name} gives #{event.target.name} a cursory glance and then emits an unimpressed, 'Eh.'"
                to_target "#{player.name} gives you a cursory glance and then emits an unimpressed, 'Eh.'"
              end

              no_target do
                to_player "After a brief consideration, you give an unimpressed, 'Eh.'"
                to_other "#{player.name} appears to consider for a moment before giving an unimpressed, 'Eh.'"
              end
            end
          end

        end
      end
    end
  end
end
