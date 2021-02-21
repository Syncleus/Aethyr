require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Asave
        class AsaveCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            log "#{player.name} initiated manual save."
            $manager.save_all
            player.output "Save complete. Check log for details."
          end

        end
      end
    end
  end
end
