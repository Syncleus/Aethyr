require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Get
        class GetCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            room = $manager.get_object(@player.container)
            if event[:from].nil?
              object = $manager.find(event[:object], room)

              if object.nil?
                @player.output("There is no #{event[:object]} to take.")
                return
              elsif not object.movable
                @player.output("You cannot take #{object.name}.")
                return
              elsif @player.inventory.full?
                @player.output("You cannot hold any more objects.")
                return
              end

              room.remove(object)
              object.container = @player.goid
              @player.inventory << object

              event[:to_player] = "You take #{object.name}."
              event[:to_other] = "#{@player.name} takes #{object.name}."
              room.out_event(event)
            else
              from = event[:from]
              container = $manager.find(from, room)
              @player.inventory.find(from) if container.nil?

              if container.nil?
                @player.output("There is no #{from}.")
                return
              elsif not container.is_a? Container
                @player.output("Not sure how to do that.")
                return
              elsif container.can? :open and container.closed?
                @player.output("You will need to open it first.")
                return
              end

              object = $manager.find(event[:object], container)

              if object.nil?
                @player.output("There is no #{event[:object]} in the #{container.name}.")
                return
              elsif not object.movable
                @player.output("You cannot take the #{object.name}.")
                return
              elsif @player.inventory.full?
                @player.output("You cannot hold any more objects.")
                return
              end

              container.remove(object)
              @player.inventory.add(object)

              event[:to_player] = "You take #{object.name} from #{container.name}."
              event[:to_other] = "#{@player.name} takes #{object.name} from #{container.name}."
              room.out_event(event)
            end
          end
        end
      end
    end
  end
end
