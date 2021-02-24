require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Pose
        class PoseCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            if event[:pose].downcase == "none"
              player.pose = nil
              player.output "You are no longer posing."
            else
              player.pose = event[:pose]
              player.output "Your pose is now: #{event[:pose]}."
            end
          end

        end
      end
    end
  end
end
