require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Drop
        class DropCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            
            room = $manager.get_object(@player.container)
            object = @player.inventory.find(self[:object])

            if object.nil?
              if response = @player.equipment.worn_or_wielded?(self[:object])
                @player.output response
              else
                @player.output "You have no #{self[:object]} to drop."
              end

              return
            end

            @player.inventory.remove(object)

            object.container = room.goid
            room.add(object)

            self[:to_player] = "You drop #{object.name}."
            self[:to_other] = "#{@player.name} drops #{object.name}."
            self[:to_blind_other] = "You hear something hit the ground."
            room.out_self(self)
          end
        end
      end
    end
  end
end
