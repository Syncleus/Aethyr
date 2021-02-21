require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Acomment
        class AcommentCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:target], event)
            if object.nil?
              player.output "Cannot find:#{event[:target]}"
              return
            end

            object.comment = event[:comment]
            player.output "Added comment: '#{event[:comment]}'\nto#{object}"
          end

        end
      end
    end
  end
end
