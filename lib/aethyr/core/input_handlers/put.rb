require "aethyr/core/actions/commands/put"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Put
        class PutHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "put"
            see_also = ["LOOK", "TAKE", "OPEN"]
            syntax_formats = ["PUT [object] IN [container]"]
            aliases = nil
            content =  <<'EOF'
Puts an object in a container. The container must be open to do so.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["put"], help_entries: PutHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^put((\s+(\d+)\s+)|\s+)(\w+)\s+in\s+(\w+)$/i
              $manager.submit_action(Aethyr::Core::Actions::Put::PutCommand.new(@player, { :item => $4, :count => $3.to_i, :container => $5 }))
            end
          end

          private

        end

        Aethyr::Extend::HandlerRegistry.register_handler(PutHandler)
      end
    end
  end
end
