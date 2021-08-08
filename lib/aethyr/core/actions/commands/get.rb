require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Get
        class GetCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action

            room = $manager.get_object(self[:agent].container)
            if self[:from].nil?
              object = $manager.find(self[:object], room)

              if object.nil?
                self[:agent].output("There is no #{self[:object]} to take.")
                return
              elsif not object.movable
                self[:agent].output("You cannot take #{object.name}.")
                return
              elsif self[:agent].inventory.full?
                self[:agent].output("You cannot hold any more objects.")
                return
              end

              room.remove(object)
              object.container = self[:agent].goid
              self[:agent].inventory << object

              self[:to_player] = "You take #{object.name}."
              self[:to_other] = "#{self[:agent].name} takes #{object.name}."
              room.out_event(event)
            else
              from = self[:from]
              container = $manager.find(from, room)
              self[:agent].inventory.find(from) if container.nil?

              if container.nil?
                self[:agent].output("There is no #{from}.")
                return
              elsif not container.is_a? Container
                self[:agent].output("Not sure how to do that.")
                return
              elsif container.can? :open and container.closed?
                self[:agent].output("You will need to open it first.")
                return
              end

              object = $manager.find(self[:object], container)

              if object.nil?
                self[:agent].output("There is no #{self[:object]} in the #{container.name}.")
                return
              elsif not object.movable
                self[:agent].output("You cannot take the #{object.name}.")
                return
              elsif self[:agent].inventory.full?
                self[:agent].output("You cannot hold any more objects.")
                return
              end

              container.remove(object)
              self[:agent].inventory.add(object)

              self[:to_player] = "You take #{object.name} from #{container.name}."
              self[:to_other] = "#{self[:agent].name} takes #{object.name} from #{container.name}."
              room.out_event(event)
            end
          end
        end
      end
    end
  end
end
