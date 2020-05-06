require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Whereis
        class WhereisCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:object], event)

            if object.nil?
              player.output "Could not find #{event[:object]}."
              return
            end

            if object.container.nil?
              if object.can? :area and not object.area.nil? and object.area != object
                area = $manager.get_object object.area || "nothing"
                player.output "#{object} is in #{area}."
              else
                player.output "#{object} is not in anything."
              end
            else
              container = $manager.get_object object.container
              if container.nil?
                player.output "Container for #{object} not found."
              else
                player.output "#{object} is in #{container}."
                event[:object] = container.goid
                whereis(event, player, room)
              end
            end
          end

        end
      end
    end
  end
end
