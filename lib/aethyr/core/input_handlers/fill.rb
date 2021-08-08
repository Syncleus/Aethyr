require "aethyr/core/actions/commands/fill"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Fill
        class FillHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "fill"
            see_also = nil
            syntax_formats = ["FILL [container] FROM [source]"]
            aliases = nil
            content =  <<'EOF'
Fill a container from a source

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["fill"], help_entries: FillHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^fill\s+(\w+)\s+from\s+(\w+)$/i
              $manager.submit_action(Aethyr::Core::Actions::Fill::FillCommand.new(@player,  :object => $1, :from => $2))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(FillHandler)
      end
    end
  end
end
