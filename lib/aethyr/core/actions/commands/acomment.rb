require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Acomment
        class AcommentCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(self[:target], self)
            if object.nil?
              player.output "Cannot find:#{self[:target]}"
              return
            end

            object.comment = self[:comment]
            player.output "Added comment: '#{self[:comment]}'\nto#{object}"
          end

        end
      end
    end
  end
end
