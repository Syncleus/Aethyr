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

            room = $manager.get_object(self[:agent].container)
            item = self[:agent].inventory.find(self[:item])

            if item.nil?
              if response = self[:agent].equipment.worn_or_wielded?(self[:item])
                self[:agent].output response
              else
                self[:agent].output "You do not seem to have a #{self[:item]}."
              end

              return
            end

            container = self[:agent].search_inv(self[:container]) || $manager.find(self[:container], room)

            if container.nil?
              self[:agent].output("There is no #{self[:container]} in which to put #{item.name}.")
              return
            elsif not container.is_a? Container
              self[:agent].output("You cannot put anything in #{container.name}.")
              return
            elsif container.can? :open and container.closed?
              self[:agent].output("You need to open #{container.name} first.")
              return
            end

            self[:agent].inventory.remove(item)
            container.add(item)

            self[:to_player] = "You put #{item.name} in #{container.name}."
            self[:to_other] = "#{self[:agent].name} puts #{item.name} in #{container.name}"

            room.out_event(event)
          end
        end
      end
    end
  end
end
