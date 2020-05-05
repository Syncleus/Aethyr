require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module LatestNews
        class LatestNewsCommand < Aethyr::Core::Actions::CommandAction
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

            if not board.is_a? Newsboard
              log board.class
            end

            offset = event[:offset] || 0
            wordwrap = player.word_wrap || 100
            limit = event[:limit] || player.page_height

            player.output board.list_latest(wordwrap, offset, limit)
          end

        end
      end
    end
  end
end
