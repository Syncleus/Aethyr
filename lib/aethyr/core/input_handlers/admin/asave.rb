require "aethyr/core/actions/commands/asave"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Asave
        class AsaveHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "asave"
            see_also = nil
            syntax_formats = ["ASAVE"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["asave"], help_entries: AsaveHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^asave$/i
              $manager.submit_action(Aethyr::Core::Actions::Asave::AsaveCommand.new(@player, ))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AsaveHandler)
      end
    end
  end
end
