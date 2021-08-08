require "aethyr/core/actions/commands/pose"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

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
            super(player, ["pose"], help_entries: PoseHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^pose\s+(.*)$/i
              pose = $1.strip
              $manager.submit_action(Aethyr::Core::Actions::Pose::PoseCommand.new(@player, :pose => pose))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(PoseHandler)
      end
    end
  end
end
