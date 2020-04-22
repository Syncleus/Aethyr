require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Areas
        class AreasHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["areas"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AreasHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^areas$/i
              areas({})
            when /^help (areas)$/i
              action_help_areas({})
            end
          end

          private
          def action_help_areas(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def areas(event)

            room = $manager.get_object(@player.container)
            player = @player
            areas = $manager.find_all('class', Area)

            if areas.empty?
              player.output "There are no areas."
              return
            end

            player.output areas.map {|a| "#{a.name} -  #{a.inventory.find_all('class', Room).length} rooms (#{a.info.terrain.area_type})" }
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AreasHandler)
      end
    end
  end
end
