require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Quit
        class QuitCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            $manager.drop_player player
          end
        end
      end
    end
  end
end
