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

            self[:agent].output "You are #{self[:agent].health}."
          end
          #Display hunger.
        end
      end
    end
  end
end
