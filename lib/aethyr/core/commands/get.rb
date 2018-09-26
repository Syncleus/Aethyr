require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module GetCommand
  class << self
    #Gets (or takes) an object and puts it in the player's inventory.
    def get(event, player, room)

      if event[:from].nil?
        object = $manager.find(event[:object], room)

        if object.nil?
          player.output("There is no #{event[:object]} to take.")
          return
        elsif not object.movable
          player.output("You cannot take #{object.name}.")
          return
        elsif player.inventory.full?
          player.output("You cannot hold any more objects.")
          return
        end

        room.remove(object)
        object.container = player.goid
        player.inventory << object

        event[:to_player] = "You take #{object.name}."
        event[:to_other] = "#{player.name} takes #{object.name}."
        room.out_event(event)
      else
        from = event[:from]
        container = $manager.find(from, room)
        player.inventory.find(from) if container.nil?

        if container.nil?
          player.output("There is no #{from}.")
          return
        elsif not container.is_a? Container
          player.output("Not sure how to do that.")
          return
        elsif container.can? :open and container.closed?
          player.output("You will need to open it first.")
          return
        end

        object = $manager.find(event[:object], container)

        if object.nil?
          player.output("There is no #{event[:object]} in the #{container.name}.")
          return
        elsif not object.movable
          player.output("You cannot take the #{object.name}.")
          return
        elsif player.inventory.full?
          player.output("You cannot hold any more objects.")
          return
        end

        container.remove(object)
        player.inventory.add(object)

        event[:to_player] = "You take #{object.name} from #{container.name}."
        event[:to_other] = "#{player.name} takes #{object.name} from #{container.name}."
        room.out_event(event)
      end
    end
    
    def get_help(event, player, room)
      player.output <<'EOF'
Command: Get
Command: Grab
Command: Take
Syntax: GET [object]
Syntax: GRAB [object'
Syntax: TAKE [object]

Pick up an object and put it in your inventory.

See also: GIVE

EOF
    end
  end

  class GetHandler < Aethyr::Extend::CommandHandler
    def initialize
      super(["get", "grab", "take"])
    end

    def input_handle(input, player)
      e = case input
      when /^(get|grab|take)\s+((\w+|\s)*)(\s+from\s+(\w+))/i
        { :action => :get, :object => $2.strip, :from => $5 }
      when /^(get|grab|take)\s+(.*)$/i
        { :action => :get, :object => $2.strip }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:GetCommand, e)
    end
    
    def help_handle(input, player)
      e = case input
      when /^(get|grab|take)$/i
        { :action => :get_help }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:GetCommand, e)
    end
  end

  Aethyr::Extend::HandlerRegistry.register_handler(GetHandler)
end