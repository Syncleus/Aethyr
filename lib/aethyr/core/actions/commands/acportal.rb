require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Acportal
        class AcportalCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            object = Admin.acreate(event, player, room)
            if event[:portal_action] and event[:portal_action].downcase != "enter"
              object.info.portal_action = event[:portal_action].downcase.to_sym
            end
          end

        end
      end
    end
  end
end
