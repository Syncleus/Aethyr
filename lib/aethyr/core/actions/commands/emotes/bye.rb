require "aethyr/core/actions/commands/emotes/emote_action"

module Aethyr
  module Core
    module Actions
      module Bye
        class ByeCommand < Aethyr::Core::Actions::EmoteAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            make_emote event, player, room do

              no_target do
                to_player "You say a hearty \"Goodbye!\" to those around you."
                to_other "#{player.name} says a hearty \"Goodbye!\""
              end

              self_target do
                player.output "Goodbye."
              end

              target do
                to_player "You say \"Goodbye!\" to #{event.target.name}."
                to_target "#{player.name} says \"Goodbye!\" to you."
                to_other "#{player.name} says \"Goodbye!\" to #{event.target.name}"
              end
            end

          end

        end
      end
    end
  end
end
