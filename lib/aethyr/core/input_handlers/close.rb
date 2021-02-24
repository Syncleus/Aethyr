require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"
require "aethyr/core/util/direction"
require "aethyr/core/help/help_entry"
require "aethyr/core/actions/commands/command_action"
require "aethyr/core/actions/commands/close"

module Aethyr
  module Core
    module Commands
      module Close
        class CloseHandler < Aethyr::Extend::CommandHandler

          include Aethyr::Direction

          def self.create_help_entries
            command = "close"
            see_also = ["LOCK", "UNLOCK", "OPEN"]
            syntax_formats = ["CLOSE [object or direction]"]
            content =  <<'EOF'
Command: Close
Syntax: CLOSE [object or direction]

Closes the object. For doors and such, it is more accurate to use the direction in which the object lies.

For example:

CLOSE north

CLOSE door


See also: LOCK, UNLOCK, OPEN
EOF
            return [Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also)]
          end

          def initialize(player)
            super(player, ["close"], help_entries: CloseHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(close|shut)\s+(\w+)$/i
              CloseCommand.new(@player, :object => $2).action()
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(CloseHandler)
      end
    end
  end
end
