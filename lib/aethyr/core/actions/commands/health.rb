require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Health
        class HealthCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            @player.output "You are #{@player.health}."
          end
          #Display hunger.
        end
      end
    end
  end
end
