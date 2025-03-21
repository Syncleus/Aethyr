require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Areas
        class AreasCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

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
      end
    end
  end
end
