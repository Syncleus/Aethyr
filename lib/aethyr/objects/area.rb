require 'aethyr/objects/container'

#An Area contains rooms and can be used to manage the weather and other area-wide information.
#Right now they don't do much but hold rooms, though.
#
#==Info
# info.terrain = Info.new
# info.terrain.area_type = :urban
class Area < GridContainer
  attr_accessor :map_type

  def initialize(*args)
    super
    info.terrain = Info.new
    info.terrain.area_type = :urban
    @article = "an"
    @generic = "area"
    @map_type = :rooms
    @map_rows = 10
    @map_columns = 10
  end

  #Returns self.
  def area
    self
  end
  
  def render_map player, position
    return "" if @map_type.eql? :none
 
    rendered = ""
    width = (@map_columns) * 4 + 1;
    height = (@map_rows) * 2 + 1;
    (0..height - 1).step(1) do |row|
      border_row = (row % 2 == 0);
      #room_row = row / 2;
      room_row = ((height - row) / 2) + (position[0] - (@map_rows / 2))
      column = 0
      until column >= width
      #(0..width).step(1) do |column|
        border_column = (column % 4 == 0);
        #room_column = column / 4;
        room_column = (column / 4) + (position[1] - (@map_columns / 2))
        #rendered += room_column.to_s
        
        room = self.find_by_position([room_column, room_row])
        #here_room = !room.nil?
        #west_room = !self.find_by_position([room_column - 1, room_row]).nil?
        #north_room = !self.find_by_position([room_column, room_row + 1]).nil?
        #north_west_room = !self.find_by_position([room_column - 1, room_row + 1]).nil?
        here_room = (room != nil && row < height - 1 && column < width - 1);
        west = self.find_by_position([room_column - 1, room_row])
        west_room = (row >= height - 1 ? false : west != nil);
        north =  self.find_by_position([room_column , room_row + 1 ])
        north_room = (column >= width - 1 ? false : north != nil);
        north_west_room = (row >= height - 1 || column >= width - 1 ? false : self.find_by_position([room_column - 1, room_row + 1]) != nil);
        
        if border_row
          if border_column
            if (here_room and north_west_room) or (west_room and north_room)
              rendered += "┼"
            elsif here_room and north_room
              rendered += "├"
            elsif here_room and west_room
              rendered += "┬"
            elsif north_west_room and west_room
              rendered += "┤"
            elsif north_west_room and north_room
              rendered += "┴"
            elsif here_room
              rendered += "┌"
            elsif west_room
              rendered += "┐"
            elsif north_west_room
              rendered += "┘"
            elsif north_room
              rendered += "└"
            else
              rendered += " "
            end
          elsif column >= 1 and ((column - 2) % 4 == 0)
            #is a row exit
            if here_room or north_room
              if here_room and north_room
                if !room.exit("north").nil? and !north.exit("south").nil?
                  rendered += "↕"
                elsif !north.exit("south").nil?
                  rendered += "↓"
                elsif !room.exit("north").nil?
                  rendered += "↑"
                else
                  rendered += "─"
                end
              else
                rendered += "─"
              end
            else
              rendered += " "
            end
          else
            if here_room or north_room
              rendered += "─"
            else
              rendered += " "
            end
          end
        else
          if border_column
            # is an intersection between the four rooms
            if here_room or west_room
              if here_room and west_room
                if !room.exit("west").nil? and !west.exit("east").nil?
                  rendered += "↔"
                elsif !west.exit("east").nil?
                  rendered += "→"
                elsif !room.exit("west").nil?
                  rendered += "←"
                else
                  rendered += "│"
                end
              else
                rendered += "│"
              end
            else
              rendered += " "
            end
          else
            #a room space
            # render the room here and append to rendered
            rendered += self.render_room room, player
            column += 2
          end
        end
        
        column += 1
      end
      rendered += "\r\n"
    end
    
    rendered
  end
  
  def render_room room, player
    return "   " if room.nil?
    me_here = room.inventory.include? player
    merchants_here = false
    zone_change_here = false
    up_here = false
    down_here = false
    mobs_here = false
    
    left_char = " "
    if zone_change_here
      left_char = "☼"
    elsif up_here
      left_char = "↑"
    elsif down_here
      left_char = "↓"
    end
    
    right_char = " "
    if mobs_here
      right_char = "*"
    elsif merchants_here
      right_char = "☻"
    end
    
    middle_char = " "
    if me_here
      middle_char = "☺"
    end
    
    if (left_char.eql? " ") and (not right_char.eql? " ")
      if mobs_here and merchants_here
        left_char = "☻"
      end
    elsif (not left_char.eql? " ") and (right_char.eql? " ")
      if zone_change_here and up_here
        right_Char = "↑"
      elsif (zone_change_here or up_here) and down_here
        right_char = "↓"
      end
    end
    
    left_char + middle_char + right_char
  end
end