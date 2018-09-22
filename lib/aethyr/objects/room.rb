require 'aethyr/objects/container'
require 'aethyr/objects/exit'

#A room is where things live. Rooms themselves need to be in other rooms (kind of) and can certainly be nested as deeply as you would like.
#Especially since doors can be set up arbitrarily. A room should be placed within an Area.
#
#===Info
# terrain (Info)
# terrain.indoors (Boolean)
# terrain.water (Boolean)
# terrain.underwater (Boolean)
# terrain.room_type (Symbol)
class Room < Container

  attr_reader :terrain

  #Create new room. Arguments same as GameObject.
  def initialize(*args)
    super(nil, *args)
    @generic = "room"
    info.terrain = Info.new
    info.terrain.indoors = false
    info.terrain.water = false
    info.terrain.underwater = false
    info.terrain.room_type = :urban
  end

  #This returns the Area object this room resides within.
  #The reason it is someone recursive is for the case where rooms
  #might be inside something other than an area
  def area
    if @container.nil?
      nil
    else
      $manager.find(@container).area
    end
  end

  #Checks if a room is indoors.
  def indoors?
    @info.indoors
  end

  #Add an object to the room.
  def add(object)
    @inventory << object

    object.container = @game_object_id

    if object.is_a? Player or object.is_a? Mobile
      object.output(self.look(object)) unless object.blind?
    end
  end

  #Returns an exit in the given direction. Direction is pretty
  #arbitrary, though.
  def exit(direction)
    @inventory.find(direction, Exit)
  end

  #Returns an array of all the exits in the room.
  def exits
    @inventory.find_all('class', Exit)
  end
  
  def players(only_visible = true, exclude = nil)
    players = Array.new
    @inventory.each do |item|
      players << item if item.is_a?(Player) and item != exclude and (!only_visible or item.visible)
    end
    players
  end
  
  def mobs(only_visible = true)
    mobs = Array.new
    @inventory.each do |item|
          mobs << item if (!only_visible or item.visible) and item.can? :alive and item.alive and !item.is_a?(Player)
    end
    mobs
  end
  
  def things(only_visible = true)
    things = Array.new
    @inventory.each do |item|
          things << item if (!only_visible or item.visible) and (!item.can? :alive or !item.alive) and !item.is_a? Exit
    end
    things
  end
  
  def exits(only_visible = true)
    exits = Array.new
    @inventory.each do |item|
          exits << item if (!only_visible or item.visible) and item.is_a? Exit
    end
    exits
  end

  #Look around the room. Player is the player that is looking (so they don't see themselves).
  #Returns a description of the room including: name of the room, room short description, visible people in the room,
  #visible objects in the room. All pretty-like.
  def look(player)
    players = Array.new
    mobs = Array.new
    things = Array.new
    exits = Array.new
    add_to_desc = String.new

    @inventory.each do |item|

      #some objects can modify the rooms description as well.
      if item.show_in_look
        add_to_desc << " " << item.show_in_look if item.show_in_look != ""
      end

      if item.is_a?(Player) and item != player and item.visible
        if item.pose
          players << "<player>#{item.name}</player>, #{item.pose}#{item.short_desc ? ' - ' + item.short_desc : ''}"
        else
          players << "<player>#{item.name}</player>#{item.short_desc ? ' - ' + item.short_desc : ''}"
        end
      elsif item.is_a?(Exit) and item.visible
        if item.can? :open and item.closed?
          exits << "<exit>#{item.alt_names[0]}</exit> (closed)"
        elsif item.can? :open and item.open?
          exits << "<exit>#{item.alt_names[0]}</exit> (open)"
        else
          exits << ("<exit>#{item.alt_names[0]}</exit>" || "[Improperly named exit]")
        end
      elsif item != player and item.visible
        if not item.quantity.nil? and item.quantity > 1
          quantity = item.quantity
        else
          quantity = item.article
        end
        
        if item.can? :alive and item.alive
          mobs << "<mob>#{item.name}</mob> [<identifier>#{item.generic}</identifier>]"
        elsif item.can? :pose and item.pose
          things << "<object>#{item.name}</object> [<identifier>#{item.generic}</identifier>] (#{item.pose})#{item.short_desc ? ' - ' + item.short_desc : ''}"
        else
          things << "<object>#{item.name}</object> [<identifier>#{item.generic}</identifier>]#{item.short_desc ? ' - ' + item.short_desc : ''}"
        end
      end
    end

    #What to show if there are no exits.
    if exits.empty?
      exits << "none"
    else
      exits.sort!
    end

    if players.empty?
      players = ""
    else
      players = "The following #{players.length <= 1 ? 'player is' : 'players are'} here:\n#{players.list(@inventory, :expanded)}\n"
    end
    
    if mobs.empty?
      mobs = ""
    else
      mobs = "The following #{mobs.length <= 1 ? 'mob is' : 'mobs are'} here:\n#{mobs.list(@inventory, :expanded)}\n"
    end

    if things.empty?
      things = ""
    else
      things = "There are the following items in the room:\n#{things.list(@inventory, :expanded)}\n"
    end

    "\n<roomtitle>#{@name}</title>\n\n#{(@short_desc || '') + add_to_desc}\n\n[Exits: #{exits.list}]\n\n#{players}#{mobs}#{things}\n"
  end
end

