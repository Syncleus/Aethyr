require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Give
        class GiveCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            
            room = $manager.get_object(@player.container)
            item = player.inventory.find(self[:item])

            if item.nil?
              if response = player.equipment.worn_or_wielded?(self[:item])
                player.output response
              else
                player.output "You do not seem to have a #{self[:item]} to give away."
              end

              return
            end

            receiver = $manager.find(self[:to], room)

            if receiver.nil?
              player.output("There is no #{self[:to]}.")
              return
            elsif not receiver.is_a? Aethyr::Core::Objects::Player and not receiver.is_a? Mobile
              player.output "You can't give something to an inanimate object."
              return
            end

            player.inventory.remove(item)
            receiver.inventory.add(item)

            self[:target] = receiver
            self[:to_player] = "You give #{item.name} to #{receiver.name}."
            self[:to_target] = "#{player.name} gives you #{item.name}."
            self[:to_other] = "#{player.name} gives #{item.name} to #{receiver.name}."

            room.out_event(self)
          end
        end
      end
    end
  end
end
