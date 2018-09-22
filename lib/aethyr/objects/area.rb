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
  end

  #Returns self.
  def area
    self
  end
  
  def render_map(player, position, map_rows = 10, map_columns = 10)
    player_room = self.inventory.find_by_id(player.container)
    
    if @map_type == :rooms
      return render_rooms(player_room, position, map_rows, map_columns)
    elsif @map_type == :world
      return render_world(player_room, position, map_rows, map_columns)
    elsif @map_type == :none
      return "This area defies the laws of physics, it can not be mapped!\r\n"
    else
      raise "Invalid map type for area!"
    end
  end
  
  private
  def render_world(player_room, position, map_rows, map_columns)
    rendered = ""
    width = map_columns
    height = map_rows
    (0..height).step(1) do |screen_row|
      row = (height - screen_row) + (position[1] - (map_rows / 2))
      (0..width).step(1) do |screen_column|
        column = screen_column + (position[0] - (map_columns / 2))
        room = self.find_by_position([column , row])
        
        if room.nil?
          rendered += " "
        elsif room.eql? player_room
          rendered += "☺"
        else
          rendered += "░"
        end
      end
      rendered += "\r\n"
    end
    rendered
  end
  
  def render_rooms(player_room, position, map_rows, map_columns)
    return "The current location doesn't appear on any maps." if position.nil?
    rendered = ""
    width = (map_columns) * 4 + 1
    height = (map_rows) * 2 + 1
    (0..height - 1).step(1) do |row|
      border_row = (row % 2 == 0);
      #room_row = row / 2;
      room_row = ((height - row) / 2) + (position[1] - (map_rows / 2))
      column = 0
      until column >= width
        border_column = (column % 4 == 0);
        room_column = (column / 4) + (position[0] - (map_rows / 2))
        
        room = self.find_by_position([room_column, room_row])
        here_room = (room != nil && row < height - 1 && column < width - 1)
        west = self.find_by_position([room_column - 1, room_row])
        west_room = (row >= height - 1 ? false : west != nil)
        north =  self.find_by_position([room_column , room_row + 1 ])
        north_room = (column >= width - 1 ? false : north != nil)
        north_west_room = (row >= height - 1 || column >= width - 1 ? false : self.find_by_position([room_column - 1, room_row + 1]) != nil)
        
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
            rendered += render_room(room, (player_room.eql? room))
            column += 2
          end
        end
        
        column += 1
      end
      rendered += "\r\n"
    end
    
    rendered
  end
  
  def room_has_nonstandard_exits(room)
    exits = room.exits.map() { |e| e.alt_names[0] }
    exits.each do |exit|
      return true unless exit.eql? "north" or exit.eql? "west" or exit.eql? "south" or exit.eql? "east" or exit.eql? "up" or exit.eql? "down"
    end
    false
  end
  
  def render_room(room, has_player)
    return "   " if room.nil?
    me_here = has_player
    merchants_here = false
    zone_change_here = room_has_nonstandard_exits(room)
    
    up_here = room.exits.map{ |e| e.alt_names[0]}.include?("up")
    down_here = room.exits.map{ |e| e.alt_names[0]}.include?("down")
    mobs_here = (!room.mobs.nil?) && (room.mobs.length > 0)
    
    left_char = " "
    if zone_change_here
      left_char = "<exit>☼</exit>"
    elsif up_here
      left_char = "<exit>↑</exit>"
    elsif down_here
      left_char = "<exit>↓</exit>"
    end
    
    right_char = " "
    if mobs_here
      right_char = "<mob>*</mob>"
    elsif merchants_here
      right_char = "<merchant>☻<merchant>"
    end
    
    middle_char = " "
    if me_here
      middle_char = "<me>☺</me>"
    end
    
    if (left_char.eql? " ") and (not right_char.eql? " ")
      if mobs_here and merchants_here
        left_char = "<merchant>☻</merchant>"
      end
    elsif (not left_char.eql? " ") and (right_char.eql? " ")
      if zone_change_here and up_here
        right_Char = "<exit>↑</exit>"
      elsif (zone_change_here or up_here) and down_here
        right_char = "<exit>↓</exit>"
      end
    end
    
    left_char + middle_char + right_char
  end
end