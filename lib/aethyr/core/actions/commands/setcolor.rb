require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Setcolor
        class SetcolorCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]
            if self[:option] == "off"
              player.io.use_color = false
              player.output "Colors disabled."
            elsif self[:option] == "on"
              player.io.use_color = true
              player.output "Colors enabled."
            elsif self[:option] == "default"
              player.io.to_default
              player.output "Colors set to defaults."
            else
              player.output player.io.set_color(self[:option], self[:color])
            end
          end

        end
      end
    end
  end
end
