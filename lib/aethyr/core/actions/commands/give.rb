require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Give
        class GiveCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            room = $manager.get_object(@player.container)
            item = player.inventory.find(event[:item])

            if item.nil?
              if response = player.equipment.worn_or_wielded?(event[:item])
                player.output response
              else
                player.output "You do not seem to have a #{event[:item]} to give away."
              end

              return
            end

            receiver = $manager.find(event[:to], room)

            if receiver.nil?
              player.output("There is no #{event[:to]}.")
              return
            elsif not receiver.is_a? Player and not receiver.is_a? Mobile
              player.output("You cannot give anything to #{receiver.name}.")
              return
            end

            player.inventory.remove(item)
            receiver.inventory.add(item)

            event[:target] = receiver
            event[:to_player] = "You give #{item.name} to #{receiver.name}."
            event[:to_target] = "#{player.name} gives you #{item.name}."
            event[:to_other] = "#{player.name} gives #{item.name} to #{receiver.name}."

            room.out_event(event)
          end
        end
      end
    end
  end
end
