require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Ew
        class EwCommand < Aethyr::Extend::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "\"Ewww!\" you exclaim, looking disgusted."
                to_other "#{player.name} exclaims, \"Eww!!\" and looks disgusted."
                to_deaf_other "#{player.name} looks disgusted."
                to_blind_other "Somone exclaims, \"Eww!!\""
              end

              self_target do
                player.output "You think you are digusting?"
              end

              target do
                to_player "You glance at #{event.target.name} and say \"Ewww!\""
                to_target "#{player.name} glances in your direction and says, \"Ewww!\""
                to_deaf_other "#{player.name} gives #{event.target.name} a disgusted look."
                to_blind_other "Somone exclaims, \"Eww!!\""
                to_other "#{player.name} glances at #{event.target.name}, saying \"Ewww!\""
              end
            end
          end

        end
      end
    end
  end
end
