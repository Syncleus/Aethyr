require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Time
        class TimeCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            @player.output $manager.time
          end

          #Display date.
        end
      end
    end
  end
end
