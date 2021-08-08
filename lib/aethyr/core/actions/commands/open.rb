require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Open
        class OpenCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action

            room = $manager.get_object(self[:agent].container)
            object = expand_direction(self[:object])
            object = player.search_inv(object) || $manager.find(object, room)

            if object.nil?
              player.output("Open what?")
            elsif not object.can? :open
              player.output("You cannot open #{object.name}.")
            else
              object.open(event)
            end
          end
        end
      end
    end
  end
end
