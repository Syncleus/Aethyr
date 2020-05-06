require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Status
        class StatusCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            @player.output("You are #{@player.health}.")
            @player.output("You are feeling #{@player.satiety}.")
            @player.output "You are currently #{@player.pose || 'standing up'}."
          end
          #Fill something.
        end
      end
    end
  end
end
