require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Aput
        class AputCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]
            if self[:object].is_a? GameObject
              object = self[:object]
            else
              self[:object] = player.container if self[:object].downcase == "here"
              object = find_object(self[:object], event)
            end

            container = find_object(self[:in], event)

            if object.nil?
              player.output "Cannot find #{self[:object]} to move."
              return
            elsif self[:in] == "!world"
              container = $manager.find object.container
              container.inventory.remove(object) unless container.nil?
              object.container = nil
              player.output "Removed #{object} from any containers."
              return
            elsif self[:in].downcase == "here"
              container = $manager.find player.container
              if container.nil?
                player.output "Cannot find #{self[:in]} "
                return
              end
            elsif container.nil?
              player.output "Cannot find #{self[:in]} "
              return
            end

            if not object.container.nil?
              current_container = $manager.find object.container
              current_container.inventory.remove(object) if current_container
            end

            unless self[:at] == nil
              position = self[:at].split('x').map{ |e| e.to_i}
            end

            if container.is_a? Inventory
              container.add(object, position)
            elsif container.is_a? Container
              container.add(object)
            else
              container.inventory.add(object, position)
              object.container = container.goid
            end

            player.output "Moved #{object} into #{container}#{self[:at] == nil ? '' : ' at ' + self[:at]}"
          end

        end
      end
    end
  end
end
