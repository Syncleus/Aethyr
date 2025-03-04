require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Wear
        class WearCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player

            object = player.inventory.find(self[:object])

            if object.nil?
              player.output("What #{self[:object]} are you trying to wear?")
              return
            elsif object.is_a? Weapon
              player.output "You must wield #{object.name}."
              return
            end

            if player.wear object
              self[:to_player] = "You put on #{object.name}."
              self[:to_other] = "#{player.name} puts on #{object.name}."
              room.out_self(self)
            end
          end

        end
      end
    end
  end
end
