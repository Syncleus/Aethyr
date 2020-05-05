require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Date
        class DateCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            @player.output $manager.date
          end
          #Show who is in the game.
        end
      end
    end
  end
end
