require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module DeletePost
        class DeletePostCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player




            board = find_board(self, room)

            if board.nil?
              player.output "What newsboard are you talking about?"
              return
            end

            post = board.get_post self[:post_id]

            if post.nil?
              player.output "No such post."
            elsif post[:author] != player.name
              player.output "You can only delete your own posts."
            else
              board.delete_post self[:post_id]
              player.output "Deleted post ##{self[:post_id]}"
            end
          end

        end
      end
    end
  end
end
