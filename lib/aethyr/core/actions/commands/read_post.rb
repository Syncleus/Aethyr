require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module ReadPost
        class ReadPostCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]
            board = find_board(event, room)

            if board.nil?
              player.output "There do not seem to be any postings here."
              return
            end

            post = board.get_post self[:post_id]
            if post.nil?
              player.output "No such posting here."
              return
            end

            if player.info.boards.nil?
              player.info.boards = {}
            end

            player.info.boards[board.goid] = self[:post_id].to_i

            player.output board.show_post(post, player.word_wrap || 80)
          end

        end
      end
    end
  end
end
