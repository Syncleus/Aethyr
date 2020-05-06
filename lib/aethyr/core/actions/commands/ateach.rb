require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Ateach
        class AteachCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:target], event)
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
