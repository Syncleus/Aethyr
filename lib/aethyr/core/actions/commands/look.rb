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
            room = $manager.get_object(@player.container)

            pre_look_data = { :can_look => true }
            @player.broadcast_from(:pre_look, pre_look_data)

            if not pre_look_data[:can_look]
              if pre_look_data[:reason].nil?
                @player.output "You cannot see."
              else
                @player.output blind_data[:reason]
              end
            else
              if self[:at]
                object = room if self[:at] == "here"
                object = object || @player.search_inv(self[:at]) || room.find(self[:at])

                if object.nil?
                  @player.output("Look at what, again?")
                  return
                end

                if object.is_a? Exit
                  @player.output object.peer
                elsif object.is_a? Room
                  @player.output("You are indoors.", true) if object.info.terrain.indoors
                  @player.output("You are underwater.", true) if object.info.terrain.underwater
                  @player.output("You are swimming.", true) if object.info.terrain.water

                  @player.output "You are in a place called #{room.name} in #{room.area ? room.area.name : "an unknown area"}.", true
                  if room.area
                    @player.output "The area is generally #{describe_area(room.area)} and this spot is #{describe_area(room)}."
                  elsif room.info.terrain.room_type
                    @player.output "Where you are standing is considered to be #{describe_area(room)}."
                  else
                    @player.output "You are unsure about anything else concerning the area."
                  end
                elsif @player == object
                  @player.output "You look over yourself and see:\n#{@player.instance_variable_get("@long_desc")}", true
                  @player.output object.show_inventory
                else
                  @player.output object.long_desc
                end
              elsif self[:in]
                object = room.find(self[:in])
                object = @player.inventory.find(self[:in]) if object.nil?

                if object.nil?
                  @player.output("Look inside what?")
                elsif not object.can? :look_inside
                  @player.output("You cannot look inside that.")
                else
                  object.look_inside(self)
                end
              else
                if not room.nil?
                  look_text = room.look(@player)
                  @player.output(look_text)
                else
                  @player.output "Nothing to look at."
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
