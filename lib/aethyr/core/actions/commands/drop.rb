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

            room = $manager.get_object(self[:agent].container)
            object = self[:agent].inventory.find(self[:object])

            if object.nil?
              if response = self[:agent].equipment.worn_or_wielded?(self[:object])
                self[:agent].output response
              else
                self[:agent].output "You have no #{self[:object]} to drop."
              end

              return
            end

            self[:agent].inventory.remove(object)

            object.container = room.goid
            room.add(object)

            self[:to_player] = "You drop #{object.name}."
            self[:to_other] = "#{self[:agent].name} drops #{object.name}."
            self[:to_blind_other] = "You hear something hit the ground."
            room.out_event(event)
          end
        end
      end
    end
  end
end
