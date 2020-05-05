require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Drop
        class DropCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            room = $manager.get_object(@player.container)
            object = @player.inventory.find(event[:object])

            if object.nil?
              if response = @player.equipment.worn_or_wielded?(event[:object])
                @player.output response
              else
                @player.output "You have no #{event[:object]} to drop."
              end

              return
            end

            @player.inventory.remove(object)

            object.container = room.goid
            room.add(object)

            event[:to_player] = "You drop #{object.name}."
            event[:to_other] = "#{@player.name} drops #{object.name}."
            event[:to_blind_other] = "You hear something hit the ground."
            room.out_event(event)
          end
        end
      end
    end
  end
end
