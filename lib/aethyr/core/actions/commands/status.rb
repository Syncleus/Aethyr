require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Status
        class StatusCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action

            self[:agent].output("You are #{self[:agent].health}.")
            self[:agent].output("You are feeling #{self[:agent].satiety}.")
            self[:agent].output "You are currently #{self[:agent].pose || 'standing up'}."
          end
          #Fill something.
        end
      end
    end
  end
end
