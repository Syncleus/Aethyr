require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Remove
        class RemoveCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]

            object = player.equipment.find(self[:object])

            if object.nil?
              player.output("What #{self[:object]} are you trying to remove?")
              return
            end

            if player.inventory.full?
              player.output("There is no room in your inventory.")
              return
            end

            if object.is_a? Weapon
              player.output("You must unwield weapons.")
              return
            end

            response = player.remove(object, self[:position])

            if response
              self[:to_player] = "You remove #{object.name}."
              self[:to_other] = "#{player.name} removes #{object.name}."
              room.out_event(event)
            else
              player.output "Could not remove #{object.name} for some reason."
            end
          end

        end
      end
    end
  end
end
