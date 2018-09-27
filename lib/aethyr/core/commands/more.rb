require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module More
        class MoreHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["more"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(MoreHandler.new(data[:game_object]))
          end
          
          def player_input(data)
            super(data)
            case data[:input]
            when /^more/i
              action({})
            when /^help more/i
              action_help({})
            end
          end
          
          private
          def action(event)
            player.more
          end
          
          def action_help(event)
            player.output <<'EOF'
Command: More
Syntax: MORE

When the output from the last command was too long to display you can issue this
command to see the next page. If there are multiple pages then this command can
be used multiple times.

See also: PAGELENGTH
EOF
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(MoreHandler)
      end
    end
  end
end
