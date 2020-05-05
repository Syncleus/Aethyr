require "aethyr/core/actions/commands/get"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Get
        class GetHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "get"
            see_also = ["GIVE"]
            syntax_formats = ["GET [object]", "GRAB [object]", "TAKE [object]"]
            aliases = ["grab", "take"]
            content =  <<'EOF'
Pick up an object and put it in your inventory.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["get", "grab", "take"], help_entries: GetHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(get|grab|take)\s+((\w+|\s)*)(\s+from\s+(\w+))/i
              $manager.submit_action(Aethyr::Core::Actions::Get::GetCommand.new(@player, { :object => $2.strip, :from => $5 }))
            when /^(get|grab|take)\s+(.*)$/i
              $manager.submit_action(Aethyr::Core::Actions::Get::GetCommand.new(@player, { :object => $2.strip }))
            end
          end

          private

          #Gets (or takes) an object and puts it in the player's inventory.

        end

        Aethyr::Extend::HandlerRegistry.register_handler(GetHandler)
      end
    end
  end
end
