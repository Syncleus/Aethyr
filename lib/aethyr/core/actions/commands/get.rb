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
            
            room = $manager.get_object(@player.container)
            if self[:from].nil?
              object = $manager.find(self[:object], room)

              if object.nil?
                @player.output("There is no #{self[:object]} to take.")
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

              self[:to_player] = "You take #{object.name}."
              self[:to_other] = "#{@player.name} takes #{object.name}."
              room.out_self(self)
            else
              from = self[:from]
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

              object = $manager.find(self[:object], container)

              if object.nil?
                @player.output("There is no #{self[:object]} in the #{container.name}.")
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

              self[:to_player] = "You take #{object.name} from #{container.name}."
              self[:to_other] = "#{@player.name} takes #{object.name} from #{container.name}."
              room.out_self(self)
            end
          end
        end
      end
    end
  end
end
