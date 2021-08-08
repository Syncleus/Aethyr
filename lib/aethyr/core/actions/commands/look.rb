require "aethyr/core/actions/commands/command_action"
require 'aethyr/core/objects/attributes/blind'

module Aethyr
  module Core
    module Actions
      module Look
        class LookCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action

            room = $manager.get_object(self[:agent].container)

            pre_look_data = { :can_look => true }
            self[:agent].broadcast_from(:pre_look, pre_look_data)

            if not pre_look_data[:can_look]
              if pre_look_data[:reason].nil?
                self[:agent].output "You cannot see."
              else
                self[:agent].output blind_data[:reason]
              end
            else
              if self[:at]
                object = room if self[:at] == "here"
                object = object || self[:agent].search_inv(self[:at]) || room.find(self[:at])

                if object.nil?
                  self[:agent].output("Look at what, again?")
                  return
                end

                if object.is_a? Exit
                  self[:agent].output object.peer
                elsif object.is_a? Room
                  self[:agent].output("You are indoors.", true) if object.info.terrain.indoors
                  self[:agent].output("You are underwater.", true) if object.info.terrain.underwater
                  self[:agent].output("You are swimming.", true) if object.info.terrain.water

                  self[:agent].output "You are in a place called #{room.name} in #{room.area ? room.area.name : "an unknown area"}.", true
                  if room.area
                    self[:agent].output "The area is generally #{describe_area(room.area)} and this spot is #{describe_area(room)}."
                  elsif room.info.terrain.room_type
                    self[:agent].output "Where you are standing is considered to be #{describe_area(room)}."
                  else
                    self[:agent].output "You are unsure about anything else concerning the area."
                  end
                elsif self[:agent] == object
                  self[:agent].output "You look over yourself and see:\n#{self[:agent].instance_variable_get("@long_desc")}", true
                  self[:agent].output object.show_inventory
                else
                  self[:agent].output object.long_desc
                end
              elsif self[:in]
                object = room.find(self[:in])
                object = self[:agent].inventory.find(self[:in]) if object.nil?

                if object.nil?
                  self[:agent].output("Look inside what?")
                elsif not object.can? :look_inside
                  self[:agent].output("You cannot look inside that.")
                else
                  object.look_inside(event)
                end
              else
                if not room.nil?
                  look_text = room.look(self[:agent])
                  self[:agent].output(look_text)
                else
                  self[:agent].output "Nothing to look at."
                end
              end
            end
          end

          private
          def describe_area(object)
            if object.is_a? Room
              result = object.terrain_type.room_text unless object.terrain_type.nil?
              result = "uncertain" if result.nil?
            elsif object.is_a? Area
              result = object.terrain_type.area_text unless object.terrain_type.nil?
              result = "uncertain" if result.nil?
            end
            result
          end

        end
      end
    end
  end
end
