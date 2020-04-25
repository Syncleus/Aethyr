require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

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
            super(player, ["restart"], RestartHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^restart$/i
              restart({})
            end
          end

          private
          def restart(event)

            room = $manager.get_object(@player.container)
            player = @player
            $manager.restart
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(RestartHandler)
      end
    end
  end
end
