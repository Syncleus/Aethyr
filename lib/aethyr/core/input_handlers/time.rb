require "aethyr/core/actions/commands/time"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Time
        class TimeHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "time"
            see_also = nil
            syntax_formats = ["TIME"]
            aliases = nil
            content =  <<'EOF'
Time

Shows the current time in Aethyr.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["time"], help_entries: TimeHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^time$/i
              $manager.submit_action(Aethyr::Core::Actions::Time::TimeCommand.new(@player, ))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(TimeHandler)
      end
    end
  end
end
