require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Alearn
        class AlearnCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
          end

        end
      end
    end
  end
end
