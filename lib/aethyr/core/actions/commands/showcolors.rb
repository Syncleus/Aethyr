require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Showcolors
        class ShowcolorsCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            player.output player.io.display.show_color_config
          end

        end
      end
    end
  end
end
