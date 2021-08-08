require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Whereis
        class WhereisCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]
            object = find_object(self[:object], event)

            if object.nil?
              player.output "Could not find #{self[:object]}."
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
                self[:object] = container.goid
                whereis(event, player, room)
              end
            end
          end

        end
      end
    end
  end
end
