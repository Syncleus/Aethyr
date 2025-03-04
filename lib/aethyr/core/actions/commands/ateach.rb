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
            

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(self[:target], self)
            if object.nil?
              player.output "Teach who what where?"
              return
            end

            alearn(self, object, room)
          end

        end
      end
    end
  end
end
