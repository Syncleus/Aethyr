require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Fill
        class FillCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action

            room = $manager.get_object(self[:agent].container)
            object = self[:agent].search_inv(self[:object]) || room.find(self[:object])
            from = self[:agent].search_inv(self[:from]) || room.find(self[:from])

            if object.nil?
              self[:agent].output("What would you like to fill?")
              return
            elsif not object.is_a? LiquidContainer
              self[:agent].output("You cannot fill #{object.name} with liquids.")
              return
            elsif from.nil?
              self[:agent].output "There isn't any #{self[:from]} around here."
              return
            elsif not from.is_a? LiquidContainer
              self[:agent].output "You cannot fill #{object.name} from #{from.name}."
              return
            elsif from.empty?
              self[:agent].output "That #{object.generic} is empty."
              return
            elsif object.full?
              self[:agent].output("That #{object.generic} is full.")
              return
            elsif object == from
              self[:agent].output "Quickly flipping #{object.name} upside-down then upright again, you manage to fill it from itself."
              return
            end
          end
          #Display time.
        end
      end
    end
  end
end
