require "aethyr/core/actions/commands/write"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Write
        class WriteHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []
            command = "write"
            see_also = nil
            syntax_formats = ["WRITE [target]"]
            aliases = nil
            content =  <<'EOF'
Write something on the specified target.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["write"], help_entries: WriteHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^write\s+(.*)/i
              $manager.submit_action(Aethyr::Core::Actions::Write::WriteCommand.new(@player, { :target => $1.strip}))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(WriteHandler)
      end
    end
  end
end
