require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module More
        class MoreCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            
            player.more
          end
        end
      end
    end
  end
end
