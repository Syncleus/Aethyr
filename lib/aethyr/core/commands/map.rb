require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Map
        class MapHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["m", "map"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(m|map)$/i
              action({})
            when /^help (m|map)$/i
              action_help({})
            end
          end

          private
          def action_help(event)
            player.output <<'EOF'
Command: Map
Syntax: MAP

Displays a map of the area.
EOF
          end

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
