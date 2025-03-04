require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Gait
        class GaitCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            if self[:phrase].nil?
              if player.info.entrance_message
                player.output "When you move, it looks something like:", true
                player.output player.exit_message("north")
              else
                player.output "You are walking normally."
              end
            elsif self[:phrase].downcase == "none"
              player.info.entrance_message = nil
              player.info.exit_message = nil
              player.output "You will now walk normally."
            else
              player.info.entrance_message = "#{self[:phrase]}, !name comes in from !direction."
              player.info.exit_message = "#{self[:phrase]}, !name leaves to !direction."

              player.output "When you move, it will now look something like:", true
              player.output player.exit_message("north")
            end
          end

        end
      end
    end
  end
end
