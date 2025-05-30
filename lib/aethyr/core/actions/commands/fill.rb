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
            
            room = $manager.get_object(@player.container)
            object = @player.search_inv(self[:object]) || room.find(self[:object])
            from = @player.search_inv(self[:from]) || room.find(self[:from])

            if object.nil?
              @player.output("What would you like to fill?")
              return
            elsif not object.is_a? LiquidContainer
              @player.output("You cannot fill #{object.name} with liquids.")
              return
            elsif from.nil?
              @player.output "There isn't any #{self[:from]} around here."
              return
            elsif not from.is_a? LiquidContainer
              @player.output "You cannot fill #{object.name} from #{from.name}."
              return
            elsif from.empty?
              @player.output "That #{object.generic} is empty."
              return
            elsif object.full?
              @player.output("That #{object.generic} is full.")
              return
            elsif object == from
              @player.output "Quickly flipping #{object.name} upside-down then upright again, you manage to fill it from itself."
              return
            end
          end
          #Display time.
        end
      end
    end
  end
end
