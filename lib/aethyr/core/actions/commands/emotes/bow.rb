require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Bow
        class BowCommand < Aethyr::Core::Actions::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You bow deeply and respectfully."
                to_other "#{player.name} bows deeply and respectfully."
                to_deaf_other event[:to_other]
              end

              self_target do
                player.output  "Huh?"
              end

              target do
                to_player  "You bow respectfully towards #{event.target.name}."
                to_target "#{player.name} bows respectfully before you."
                to_other "#{player.name} bows respectfully towards #{event.target.name}."
                to_deaf_other event[:to_other]
              end
            end

          end

        end
      end
    end
  end
end
