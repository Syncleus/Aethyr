require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Er
        class ErCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            make_emote event, player, room do
              no_target do
                to_player "With a look of uncertainty, you say, \"Er...\""
                to_other "With a look of uncertainty, #{player.name} says, \"Er...\""
              end

              target do
                to_player "Looking at #{target.name} uncertainly, you say, \"Er...\""
                to_other "Looking at #{target.name} uncertainly, #{player.name} says, \"Er...\""
                to_target "Looking at you uncertainly, #{player.name} says, \"Er...\""
              end
            end
          end

        end
      end
    end
  end
end
