require "aethyr/core/actions/commands/status"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Status
        class StatusHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "status"
            see_also = ["INVENTORY", "HUNGER", "HEALTH"]
            syntax_formats = ["STATUS", "STAT", "ST"]
            aliases = nil
            content =  <<'EOF'
Shows your current health, hunger/satiety, and position.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["st", "stat", "status"], help_entries: StatusHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(st|stat|status)$/i
              $manager.submit_action(Aethyr::Core::Actions::Status::StatusCommand.new(@player, {}))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(StatusHandler)
      end
    end
  end
end
