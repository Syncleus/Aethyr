require "aethyr/core/actions/commands/acdoor"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Acdoor
        class AcdoorHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "acdoor"
            see_also = nil
            syntax_formats = ["ACDOOR [DIRECTION] [EXIT_ROOM]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["acdoor"], help_entries: AcdoorHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^acdoor\s+(\w+)$/i
              direction = $1
              $manager.submit_action(Aethyr::Core::Actions::Acdoor::AcdoorCommand.new(@player, :direction => direction))
            when /^acdoor\s+(\w+)\s+(.*)$/i
              direction = $1.strip
              exit_room = $2.strip
              $manager.submit_action(Aethyr::Core::Actions::Acdoor::AcdoorCommand.new(@player, :direction => direction, :exit_room => exit_room))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AcdoorHandler)
      end
    end
  end
end
