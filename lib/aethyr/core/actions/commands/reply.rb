require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Reply
        class ReplyCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            unless @player.reply_to
              @player.output "There is no one to reply to."
              return
            end

            event[:target] = @player.reply_to

            action_tell(event)
          end
        end
      end
    end
  end
end
