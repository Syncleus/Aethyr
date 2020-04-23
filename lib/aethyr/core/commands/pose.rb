require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Pose
        class PoseHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["pose"])
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^pose\s+(.*)$/i
              pose = $1.strip
              pose({:pose => pose})
            when /^help (pose)$/i
              action_help_pose({})
            end
          end

          private
          def action_help_pose(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def pose(event)

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
        Aethyr::Extend::HandlerRegistry.register_handler(PoseHandler)
      end
    end
  end
end
