require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Remove
        class RemoveCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            object = player.equipment.find(event[:object])

            if object.nil?
              player.output("What #{event[:object]} are you trying to remove?")
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

            response = player.remove(object, event[:position])

            if response
              event[:to_player] = "You remove #{object.name}."
              event[:to_other] = "#{player.name} removes #{object.name}."
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
