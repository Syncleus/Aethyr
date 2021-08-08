require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module ListUnread
        class ListUnreadCommand < Aethyr::Extend::CommandAction
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

            if player.info.boards.nil?
              player.info.boards = {}
            end

            player.output board.list_since(player.info.boards[board.goid], player.word_wrap)
          end

        end
      end
    end
  end
end
