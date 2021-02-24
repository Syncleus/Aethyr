require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module All
        class AllCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            board = find_board(event, room)

            if board.nil?
              player.output "There do not seem to be any postings here."
              return
            end

            wordwrap = player.word_wrap || 100

            player.output board.list_latest(wordwrap, 0, nil)
          end

        end
      end
    end
  end
end
