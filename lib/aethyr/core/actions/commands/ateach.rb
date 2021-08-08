require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Ateach
        class AteachCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]
            object = find_object(self[:target], event)
            if object.nil?
              player.output "Teach who what where?"
              return
            end

            alearn(event, object, room)
          end

        end
      end
    end
  end
end
