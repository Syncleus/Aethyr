require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Alearn
        class AlearnHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "alearn"
            see_also = nil
            syntax_formats = ["ALEARN [SKILL]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["alearn"], AlearnHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^alearn\s+(\w+)$/i
              skill = $1
              alearn({:skill => skill})
            end
          end

          private
          def alearn(event)

            room = $manager.get_object(@player.container)
            player = @player
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AlearnHandler)
      end
    end
  end
end
