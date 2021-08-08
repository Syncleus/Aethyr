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

            unless self[:agent].reply_to
              self[:agent].output "There is no one to reply to."
              return
            end

            self[:target] = self[:agent].reply_to

            action_tell(event)
          end
        end
      end
    end
  end
end
