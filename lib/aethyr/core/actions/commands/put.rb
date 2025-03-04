require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Put
        class PutCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            
            room = $manager.get_object(@player.container)
            item = @player.inventory.find(self[:item])

            if item.nil?
              if response = @player.equipment.worn_or_wielded?(self[:item])
                @player.output response
              else
                @player.output "You do not seem to have a #{self[:item]}."
              end

              return
            end

            container = @player.search_inv(self[:container]) || $manager.find(self[:container], room)

            if container.nil?
              @player.output("There is no #{self[:container]} in which to put #{item.name}.")
              return
            elsif not container.is_a? Container
              @player.output("You cannot put anything in #{container.name}.")
              return
            elsif container.can? :open and container.closed?
              @player.output("You need to open #{container.name} first.")
              return
            end

            @player.inventory.remove(item)
            container.add(item)

            self[:to_player] = "You put #{item.name} in #{container.name}."
            self[:to_other] = "#{@player.name} puts #{item.name} in #{container.name}"

            room.out_self(self)
          end
        end
      end
    end
  end
end
