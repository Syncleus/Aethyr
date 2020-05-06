require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Close
        class CloseCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action()
            event = @data
            room = $manager.get_object(@player.container)
            object = expand_direction(event[:object])
            object = @player.search_inv(object) || $manager.find(object, room)

            if object.nil?
              @player.output("Close what?")
            elsif not object.can? :open
              @player.output("You cannot close #{object.name}.")
            else
              object.close(event)
            end
          end
        end
      end
    end
  end
end
