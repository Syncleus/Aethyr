require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Restart
        class RestartCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            $manager.restart
          end

        end
      end
    end
  end
end
