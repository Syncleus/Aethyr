require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Aforce
        class AforceCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:target], event)
            if object.nil?
              player.output "Force who?"
              return
            elsif object.is_a? Player
              object.handle_input(event[:command])
            else
              player.output "You can only force other players to execute a command."
            end

          end

        end
      end
    end
  end
end
