require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Close
        class CloseCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action()

            room = $manager.get_object(self[:agent].container)
            object = expand_direction(self[:object])
            object = self[:agent].search_inv(object) || $manager.find(object, room)

            if object.nil?
              self[:agent].output("Close what?")
            elsif not object.can? :open
              self[:agent].output("You cannot close #{object.name}.")
            else
              object.close(event)
            end
          end
        end
      end
    end
  end
end
