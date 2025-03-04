require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Acroom
        class AcroomCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            area = nil
            if room.container
              area = $manager.get_object(room.container)
            end

            unless area.nil? or area.map_type.eql? :none
              current_pos = area.position(room)
              new_pos = current_pos.dup
              case self[:out_dir].downcase.strip
                when "north"
                  new_pos[1] += 1
                when "south"
                  new_pos[1] -= 1
                when "west"
                  new_pos[0] -= 1
                when "east"
                  new_pos[0] += 1
                when "northeast"
                  player.output "Can not create a #{self[:out_dir]} exit in a mappable area at this time"
                  return
                when "northwest"
                  player.output "Can not create a #{self[:out_dir]} exit in a mappable area at this time"
                  return
                when "southeast"
                  player.output "Can not create a #{self[:out_dir]} exit in a mappable area at this time"
                  return
                when "southwest"
                  player.output "Can not create a #{self[:out_dir]} exit in a mappable area at this time"
                  return
                else
                  new_pos = nil
              end
              new_pos_text = new_pos.map{ |e| e.to_s}.join('x') unless new_pos.nil?
            end

            unless new_pos.nil? or area.find_by_position(new_pos).nil?
              player.output "There is already a room at the coordinates (#{new_pos_text}) that would be occupied by the new room, aborting"
              return
            end

            new_room = $manager.create_object(Room, area, new_pos, nil, :@name => self[:name])
            out_exit = $manager.create_object(Exit, room, nil, new_room.goid, :@alt_names => [self[:out_dir]])
            in_exit = $manager.create_object(Exit, new_room, nil, room.goid, :@alt_names => [self[:in_dir]])

            player.output "Created: #{new_room}#{new_pos.nil? ? '' : ' @ ' + new_pos_text}"
            player.output "Created: #{out_exit}"
            player.output "Created: #{in_exit}"

            if !area.nil? and area.map_type.eql? :world
              west = area.find_by_position([new_pos[0] - 1, new_pos[1]])
              east = area.find_by_position([new_pos[0] + 1, new_pos[1]])
              north = area.find_by_position([new_pos[0], new_pos[1] + 1])
              south = area.find_by_position([new_pos[0], new_pos[1] - 1])
              if !west.nil? and !west.eql? room
                out_exit = $manager.create_object(Exit, new_room, nil, west.goid, :@alt_names => ["west"])
                in_exit = $manager.create_object(Exit, west, nil, new_room.goid, :@alt_names => ["east"])
                player.output "Created: #{out_exit}"
                player.output "Created: #{in_exit}"
                west.output "There is a small flash of light as a new room appears to the east."
              elsif !east.nil? and !east.eql? room
                out_exit = $manager.create_object(Exit, new_room, nil, east.goid, :@alt_names => ["east"])
                in_exit = $manager.create_object(Exit, east, nil, new_room.goid, :@alt_names => ["west"])
                player.output "Created: #{out_exit}"
                player.output "Created: #{in_exit}"
                east.output "There is a small flash of light as a new room appears to the west."
              elsif !north.nil? and !north.eql? room
                out_exit = $manager.create_object(Exit, new_room, nil, north.goid, :@alt_names => ["north"])
                in_exit = $manager.create_object(Exit, north, nil, new_room.goid, :@alt_names => ["south"])
                player.output "Created: #{out_exit}"
                player.output "Created: #{in_exit}"
                north.output "There is a small flash of light as a new room appears to the south."
              elsif !south.nil? and !south.eql? room
                out_exit = $manager.create_object(Exit, new_room, nil, south.goid, :@alt_names => ["south"])
                in_exit = $manager.create_object(Exit, south, nil, new_room.goid, :@alt_names => ["north"])
                player.output "Created: #{out_exit}"
                player.output "Created: #{in_exit}"
                south.output "There is a small flash of light as a new room appears to the north."
              end
            end

            if room
              room.output "There is a small flash of light as a new room appears to the #{self[:out_dir]}."
            end

          end

        end
      end
    end
  end
end
