require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Alearn
        class AlearnCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]
          end

        end
      end
    end
  end
end
