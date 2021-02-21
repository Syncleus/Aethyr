require "aethyr/core/actions/commands/alog"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Alog
        class AlogHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "alog"
            see_also = nil
            syntax_formats = ["ALOG (DEBUG|NORMAL|HIGH|ULTIMATE|OFF)", "ALOG (PLAYER|SERVER|SYSTEM) [LINES]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["alog"], help_entries: AlogHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^alog\s+(\w+)(\s+(\d+))?$/i
              command = $1
              value = $3.downcase if $3
              $manager.submit_action(Aethyr::Core::Actions::Alog::AlogCommand.new(@player, {:command => command, :value => value}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AlogHandler)
      end
    end
  end
end
