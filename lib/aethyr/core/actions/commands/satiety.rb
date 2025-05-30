require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Satiety
        class SatietyCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            
            @player.output "You are #{@player.satiety}."
          end
          #Display status.
        end
      end
    end
  end
end
