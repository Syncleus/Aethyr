require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Acportal
        class AcportalCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            object = Admin.acreate(self, player, room)
            if self[:portal_action] and self[:portal_action].downcase != "enter"
              object.info.portal_action = self[:portal_action].downcase.to_sym
            end
          end

        end
      end
    end
  end
end
