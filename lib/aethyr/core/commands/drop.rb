require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module DropCommand
  class << self
    #Drops an item from the player's inventory into the room.
    def drop(event, player, room)
      object = player.inventory.find(event[:object])

      if object.nil?
        if response = player.equipment.worn_or_wielded?(event[:object])
          player.output response
        else
          player.output "You have no #{event[:object]} to drop."
        end

        return
      end

      player.inventory.remove(object)

      object.container = room.goid
      room.add(object)

      event[:to_player] = "You drop #{object.name}."
      event[:to_other] = "#{player.name} drops #{object.name}."
      event[:to_blind_other] = "You hear something hit the ground."
      room.out_event(event)
    end
    
    def drop_help(event, player, room)
      player.output <<'EOF'
Command: Drop
Syntax: DROP [object]

Removes an object from your inventory and places it gently on the ground.

See also: GET, TAKE, GRAB

EOF
    end
  end

  class DropHandler < Aethyr::Extend::CommandHandler
    def initialize
      super(["drop"])
    end

    def input_handle(input, player)
      e = case input
      when /^drop\s+((\w+\s*)*)$/i
        { :action => :drop, :object => $1.strip }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:DropCommand, e)
    end
    
    def help_handle(input, player)
      e = case input
      when /^drop$/i
        { :action => :drop_help }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:DropCommand, e)
    end
  end

  Aethyr::Extend::HandlerRegistry.register_handler(DropHandler)
end