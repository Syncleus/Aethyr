require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Terrain
        class TerrainHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["terrain"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(TerrainHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^terrain\s+area\s+(.*)$/i
              target = "area"
              value = $1
              terrain({:target => target, :value => value})
            when /^terrain\s+(room|here)\s+(type|indoors|underwater|water)\s+(.*)$/
              target = "room"
              setting = $2.downcase
              value = $3
              terrain({:target => target, :setting => setting, :value => value})
            when /^help (terrain)$/i
              action_help_terrain({})
            end
          end

          private
          def action_help_terrain(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def terrain(event)

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
        Aethyr::Extend::HandlerRegistry.register_handler(TerrainHandler)
      end
    end
  end
end
