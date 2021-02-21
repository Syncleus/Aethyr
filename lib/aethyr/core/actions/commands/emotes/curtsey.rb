require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Curtsey
        class CurtseyCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player  "You perform a very graceful curtsey."
                to_other "#{player.name} curtseys quite gracefully."
                to_deaf_other event[:to_other]
              end

              self_target do
                player.output "Hm? How do you do that?"
              end

              target do
                to_player "You curtsey gracefully and respectfully towards #{event.target.name}."
                to_target "#{player.name} curtseys gracefully and respectfully in your direction."
                to_other "#{player.name} curtseys gracefully and respectfully towards #{event.target.name}."
                to_deaf_other event[:to_other]
              end

            end
          end

        end
      end
    end
  end
end
