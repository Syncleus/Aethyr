require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Ahide
        class AhideCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:object], event)

            if object.nil?
              player.output "Cannot find #{event[:object]}."
              return
            end

            if event[:hide]
              object.show_in_look = ""
              player.output "#{object.name} is now hidden."
            elsif object.show_in_look == ""
              object.show_in_look = false
              player.output "#{object.name} is no longer hidden."
            else
              player.output "This object is not hidden."
            end
          end

        end
      end
    end
  end
end
