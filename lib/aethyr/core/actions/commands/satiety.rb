require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Satiety
        class SatietyCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            @player.output "You are #{@player.satiety}."
          end
          #Display status.
        end
      end
    end
  end
end
