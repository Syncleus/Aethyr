require "aethyr/core/actions/commands/more"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module More
        class MoreHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "more"
            see_also = ["PAGELENGTH"]
            syntax_formats = ["MORE"]
            aliases = nil
            content =  <<'EOF'
When the output from the last command was too long to display you can issue this
command to see the next page. If there are multiple pages then this command can
be used multiple times.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["more"], help_entries: MoreHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^more/i
              $manager.submit_action(Aethyr::Core::Actions::More::MoreCommand.new(@player, ))
            end
          end

          private

        end

        Aethyr::Extend::HandlerRegistry.register_handler(MoreHandler)
      end
    end
  end
end
