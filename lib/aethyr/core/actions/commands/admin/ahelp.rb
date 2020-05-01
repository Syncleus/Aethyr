require "aethyr/core/registry"
require "aethyr/core/actions/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Ahelp
        class AhelpHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "ahelp"
            see_also = nil
            syntax_formats = ["AHELP"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["ahelp"], help_entries: AhelpHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^ahelp(.*)$/i
              object = $1
              ahelp({:object => object})
            end
          end

          private
          def ahelp(event)

            room = $manager.get_object(@player.container)
            player = @player
            Generic.help(event, player, room)
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AhelpHandler)
      end
    end
  end
end
