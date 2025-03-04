require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Time
        class TimeCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            
            @player.output $manager.time
          end

          #Display date.
        end
      end
    end
  end
end
