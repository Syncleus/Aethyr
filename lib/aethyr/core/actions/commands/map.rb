require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Map
        class MapCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            
            room = $manager.get_object(@player.container)
            @player.output(room.area.render_map(@player, room.area.position(room)))
          end
        end
      end
    end
  end
end
