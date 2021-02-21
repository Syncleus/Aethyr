require "aethyr/core/actions/commands/restart"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Restart
        class RestartHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "restart"
            see_also = nil
            syntax_formats = ["RESTART"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["restart"], help_entries: RestartHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^restart$/i
              $manager.submit_action(Aethyr::Core::Actions::Restart::RestartCommand.new(@player, {}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(RestartHandler)
      end
    end
  end
end
