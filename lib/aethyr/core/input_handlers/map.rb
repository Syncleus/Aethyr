require "aethyr/core/registry"
require "aethyr/core/actions/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Map
        class MapHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "map"
            see_also = nil
            syntax_formats = ["MAP"]
            aliases = ["m"]
            content =  <<'EOF'
Displays a map of the area.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["m", "map"], help_entries: MapHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(m|map)$/i
              action({})
            end
          end

          private
          def action(event)
            room = $manager.get_object(@player.container)
            player.output(room.area.render_map(player, room.area.position(room)))
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(MapHandler)
      end
    end
  end
end
