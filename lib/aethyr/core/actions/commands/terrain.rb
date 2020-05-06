require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Terrain
        class TerrainCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            if event[:target] == "area"
              if room.area.nil?
                player.output "This room is not in an area."
                return
              end

              room.area.info.terrain.area_type = event[:value].downcase.to_sym

              player.output "Set #{room.area.name} terrain type to #{room.area.info.terrain.area_type}"

              return
            end

            case event[:setting].downcase
            when "type"
              room.info.terrain.room_type = event[:value].downcase.to_sym
              player.output "Set #{room.name} terrain type to #{room.info.terrain.room_type}"
            when "indoors"
              if event[:value] =~ /yes|true/i
                room.info.terrain.indoors = true
                player.output "Room is now indoors."
              elsif event[:value] =~ /no|false/i
                room.info.terrain.indoors = false
                player.output "Room is now outdoors."
              else
                player.output "Indoors: yes or no?"
              end
            when "water"
              if event[:value] =~ /yes|true/i
                room.info.terrain.water = true
                player.output "Room is now water."
              elsif event[:value] =~ /no|false/i
                room.info.terrain.water = false
                player.output "Room is now dry."
              else
                player.output "Water: yes or no?"
              end
            when "underwater"
              if event[:value] =~ /yes|true/i
                room.info.terrain.underwater = true
                player.output "Room is now underwater."
              elsif event[:value] =~ /no|false/i
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
