require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module GiveCommand
  class << self
    #Gives an item to someone else.
    def give(event, player, room)
      item = player.inventory.find(event[:item])

      if item.nil?
        if response = player.equipment.worn_or_wielded?(event[:item])
          player.output response
        else
          player.output "You do not seem to have a #{event[:item]} to give away."
        end

        return
      end

      receiver = $manager.find(event[:to], room)

      if receiver.nil?
        player.output("There is no #{event[:to]}.")
        return
      elsif not receiver.is_a? Player and not receiver.is_a? Mobile
        player.output("You cannot give anything to #{receiver.name}.")
        return
      end

      player.inventory.remove(item)
      receiver.inventory.add(item)

      event[:target] = receiver
      event[:to_player] = "You give #{item.name} to #{receiver.name}."
      event[:to_target] = "#{player.name} gives you #{item.name}."
      event[:to_other] = "#{player.name} gives #{item.name} to #{receiver.name}."

      room.out_event(event)
    end
    
    def give_help(event, player, room)
      player.output <<'EOF'
Command: Give
Syntax: GIVE [object] TO [person]

Give an object to someone else. Beware, though, they may not want to give it back.

At the moment, the object must be in your inventory.

See also: GET

EOF
    end
  end

  class GiveHandler < Aethyr::Extend::CommandHandler
    def initialize
      super(["give"])
    end

    def input_handle(input, player)
      e = case input
      when /^give\s+((\w+\s*)*)\s+to\s+(\w+)/i
        { :action => :give, :item => $2.strip, :to => $3 }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:GiveCommand, e)
    end
    
    def help_handle(input, player)
      e = case input
      when /^give$/i
        { :action => :give_help }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:GiveCommand, e)
    end
  end

  Aethyr::Extend::HandlerRegistry.register_handler(GiveHandler)
end