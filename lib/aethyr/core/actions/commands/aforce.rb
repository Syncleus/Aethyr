require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Aforce
        class AforceCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(self[:target], self)
            if object.nil?
              player.output "Force who?"
              return
            elsif object.is_a? Player
              object.handle_input(self[:command])
            else
              player.output "You can only force other players to execute a command."
            end

          end

        end
      end
    end
  end
end
