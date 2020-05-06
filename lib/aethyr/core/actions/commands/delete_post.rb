require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module DeletePost
        class DeletePostCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player




            board = find_board(event, room)

            if board.nil?
              player.output "What newsboard are you talking about?"
              return
            end

            post = board.get_post event[:post_id]

            if post.nil?
              player.output "No such post."
            elsif post[:author] != player.name
              player.output "You can only delete your own posts."
            else
              board.delete_post event[:post_id]
              player.output "Deleted post ##{event[:post_id]}"
            end
          end

        end
      end
    end
  end
end
