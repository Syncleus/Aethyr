require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module WritePost
        class WritePostCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            board = find_board(self, room)

            if board.nil?
              player.output "There do not seem to be any postings here."
              return
            end

            player.output("What is the subject of this post?", true)

            player.expect do |subj|
              player.editor do |message|
                unless message.nil?
                  post_id = board.save_post(player, subj, self[:reply_to], message)
                  player.output "You have written post ##{post_id}."
                  if board.announce_new
                    area = $manager.get_object(board.container).area
                    area.output board.announce_new
                  end
                end
              end
            end
          end

        end
      end
    end
  end
end
