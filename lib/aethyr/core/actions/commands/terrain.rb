require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Terrain
        class TerrainCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action


            room = $manager.get_object(self[:agent].container)
            player = self[:agent]
            if self[:target] == "area"
              if room.area.nil?
                player.output "This room is not in an area."
                return
              end

              room.area.info.terrain.area_type = self[:value].downcase.to_sym

              player.output "Set #{room.area.name} terrain type to #{room.area.info.terrain.area_type}"

              return
            end

            case self[:setting].downcase
            when "type"
              room.info.terrain.room_type = self[:value].downcase.to_sym
              player.output "Set #{room.name} terrain type to #{room.info.terrain.room_type}"
            when "indoors"
              if self[:value] =~ /yes|true/i
                room.info.terrain.indoors = true
                player.output "Room is now indoors."
              elsif self[:value] =~ /no|false/i
                room.info.terrain.indoors = false
                player.output "Room is now outdoors."
              else
                player.output "Indoors: yes or no?"
              end
            when "water"
              if self[:value] =~ /yes|true/i
                room.info.terrain.water = true
                player.output "Room is now water."
              elsif self[:value] =~ /no|false/i
                room.info.terrain.water = false
                player.output "Room is now dry."
              else
                player.output "Water: yes or no?"
              end
            when "underwater"
              if self[:value] =~ /yes|true/i
                room.info.terrain.underwater = true
                player.output "Room is now underwater."
              elsif self[:value] =~ /no|false/i
                room.info.terrain.underwater = false
                player.output "Room is now above water."
              else
                player.output "Underwater: yes or no?"
              end
            else
              player.output "What are you trying to set?"
            end
          end

        end
      end
    end
  end
end
