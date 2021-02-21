require "aethyr/core/actions/commands/areas"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Areas
        class AreasHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "areas"
            see_also = nil
            syntax_formats = ["AREAS"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["areas"], help_entries: AreasHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^areas$/i
              $manager.submit_action(Aethyr::Core::Actions::Areas::AreasCommand.new(@player, {}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AreasHandler)
      end
    end
  end
end
