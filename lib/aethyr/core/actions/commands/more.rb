require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module More
        class MoreCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            player.more
          end
        end
      end
    end
  end
end
