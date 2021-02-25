require "aethyr/core/actions/commands/date"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Date
        class DateHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "date"
            see_also = nil
            syntax_formats = ["DATE"]
            aliases = nil
            content =  <<'EOF'
Date

Shows the current date in Aethyr.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["date"], help_entries: DateHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^date$/i
              $manager.submit_action(Aethyr::Core::Actions::Date::DateCommand.new(@player, {}))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(DateHandler)
      end
    end
  end
end
