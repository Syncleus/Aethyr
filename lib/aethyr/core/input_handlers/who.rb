require "aethyr/core/actions/commands/who"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Who
        class WhoHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "who"
            see_also = nil
            syntax_formats = ["WHO"]
            aliases = nil
            content =  <<'EOF'
This will list everyone else who is currently in Aethyr and where they happen to be at the moment.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["who"], help_entries: WhoHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^who$/i
              $manager.submit_action(Aethyr::Core::Actions::Who::WhoCommand.new(@player, {}))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(WhoHandler)
      end
    end
  end
end
