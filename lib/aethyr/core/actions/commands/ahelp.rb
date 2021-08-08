require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Ahelp
        class AhelpCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]
            Generic.help(event, player, room)
          end

        end
      end
    end
  end
end
