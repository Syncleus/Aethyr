require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Aput
        class AputCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            if event[:object].is_a? GameObject
              object = event[:object]
            else
              event[:object] = player.container if event[:object].downcase == "here"
              object = find_object(event[:object], event)
            end

            container = find_object(event[:in], event)

            if object.nil?
              player.output "Cannot find #{event[:object]} to move."
              return
            elsif event[:in] == "!world"
              container = $manager.find object.container
              container.inventory.remove(object) unless container.nil?
              object.container = nil
              player.output "Removed #{object} from any containers."
              return
            elsif event[:in].downcase == "here"
              container = $manager.find player.container
              if container.nil?
                player.output "Cannot find #{event[:in]} "
                return
              end
            elsif container.nil?
              player.output "Cannot find #{event[:in]} "
              return
            end

            if not object.container.nil?
              current_container = $manager.find object.container
              current_container.inventory.remove(object) if current_container
            end

            unless event[:at] == nil
              position = event[:at].split('x').map{ |e| e.to_i}
            end

            if container.is_a? Inventory
              container.add(object, position)
            elsif container.is_a? Container
              container.add(object)
            else
              container.inventory.add(object, position)
              object.container = container.goid
            end

            player.output "Moved #{object} into #{container}#{event[:at] == nil ? '' : ' at ' + event[:at]}"
          end

        end
      end
    end
  end
end
