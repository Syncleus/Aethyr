require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Wear
        class WearCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player

            object = player.inventory.find(event[:object])

            if object.nil?
              player.output("What #{event[:object]} are you trying to wear?")
              return
            elsif object.is_a? Weapon
              player.output "You must wield #{object.name}."
              return
            end

            if player.wear object
              event[:to_player] = "You put on #{object.name}."
              event[:to_other] = "#{player.name} puts on #{object.name}."
              room.out_event(event)
            end
          end

        end
      end
    end
  end
end
