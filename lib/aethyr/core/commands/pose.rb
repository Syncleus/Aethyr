require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Pose
        class PoseHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "pose"
            see_also = nil
            syntax_formats = ["POSE"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["pose"], PoseHandler.create_help_entries)
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
            end
          end

          private
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
