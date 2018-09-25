require "aethyr/core/commands/command"

module Generic
  class << self
    #Look
    def look(event, player, room)
      if player.blind?
        player.output "You cannot see while you are blind."
      else
        if event[:at]
          object = room if event[:at] == "here"
          object = object || player.search_inv(event[:at]) || room.find(event[:at])

          if object.nil?
            player.output("Look at what, again?")
            return
          end

          if object.is_a? Exit
            player.output object.peer
          elsif object.is_a? Room
            player.output("You are indoors.", true) if object.info.terrain.indoors
            player.output("You are underwater.", true) if object.info.terrain.underwater
            player.output("You are swimming.", true) if object.info.terrain.water

            player.output "You are in a place called #{room.name} in #{room.area ? room.area.name : "an unknown area"}.", true
            if room.area
              player.output "The area is generally #{describe_area(room.area)} and this spot is #{describe_area(room)}."
            elsif room.info.terrain.room_type
              player.output "Where you are standing is considered to be #{describe_area(room)}."
            else
              player.output "You are unsure about anything else concerning the area."
            end
          elsif player == object
            player.output "You look over yourself and see:\n#{player.instance_variable_get("@long_desc")}", true
            player.output object.show_inventory
          else
            player.output object.long_desc
          end
        elsif event[:in]
          object = room.find(event[:in])
          object = player.inventory.find(event[:in]) if object.nil?

          if object.nil?
            player.output("Look inside what?")
          elsif not object.can? :look_inside
            player.output("You cannot look inside that.")
          else
            object.look_inside(event)
          end
        else
          if not room.nil?
            player.output(room.look(player))
          else
            player.output "Nothing to look at."
          end
        end
      end
    end
  end
  
  class LookCommand < Command
    def initialize
      super("Look")
    end
    
    def handle(input, player)
      e = case input
      when /^(l|look)$/i
        { :action => :look }
      when /^(l|look)\s+(in|inside)\s+(.*)$/i
        { :action => :look, :in => $3 }
      when /^(l|look)\s+(.*)$/i
        { :action => :look, :at => $2 }
      else
        nil
      end
      
      return nil if e.nil?
      Event.new(:Generic, e)
    end
  end
  
  Aethyr::Extend::CommandRegistry.register_handler(LookCommand)
end