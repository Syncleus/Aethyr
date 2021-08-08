require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Quit
        class QuitCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action

            $manager.drop_player self[:agent]
          end
        end
      end
    end
  end
end
