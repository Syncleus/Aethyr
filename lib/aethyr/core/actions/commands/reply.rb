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
            
            unless @player.reply_to
              @player.output "There is no one to reply to."
              return
            end

            self[:target] = @player.reply_to

            action_tell(self)
          end
        end
      end
    end
  end
end
