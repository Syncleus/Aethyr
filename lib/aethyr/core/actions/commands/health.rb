require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Health
        class HealthCommand < Aethyr::Core::Actions::CommandAction
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
