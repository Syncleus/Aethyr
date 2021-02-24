require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Date
        class DateCommand < Aethyr::Extend::CommandAction
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
