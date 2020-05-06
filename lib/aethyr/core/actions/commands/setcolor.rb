require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Setcolor
        class SetcolorCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            if event[:option] == "off"
              player.io.use_color = false
              player.output "Colors disabled."
            elsif event[:option] == "on"
              player.io.use_color = true
              player.output "Colors enabled."
            elsif event[:option] == "default"
              player.io.to_default
              player.output "Colors set to defaults."
            else
              player.output player.io.set_color(event[:option], event[:color])
            end
          end

        end
      end
    end
  end
end
