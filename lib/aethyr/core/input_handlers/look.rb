require "aethyr/core/actions/commands/look"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Look
        class LookHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "look"
            see_also = nil
            syntax_formats = ["LOOK", "LOOK [object]", "LOOK IN [object]"]
            aliases = ["l"]
            content =  <<'EOF'
Look by itself will show you your surroundings.

Look followed by an object will look at that object.

Look IN will look inside of a container (if it is open).

'l' is a shortcut for look.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["l", "look"], help_entries: LookHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(l|look)$/i
              $manager.submit_action(Aethyr::Core::Actions::Look::LookCommand.new(@player, {}))
            when /^(l|look)\s+(in|inside)\s+(.*)$/i
              $manager.submit_action(Aethyr::Core::Actions::Look::LookCommand.new(@player, { :in => $3 }))
            when /^(l|look)\s+(.*)$/i
              $manager.submit_action(Aethyr::Core::Actions::Look::LookCommand.new(@player, { :at => $2 }))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(LookHandler)
      end
    end
  end
end
