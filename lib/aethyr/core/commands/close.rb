require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module CloseCommand
  class << self
    #Close things...that are open
    def close(event, player, room)
      object = expand_direction(event[:object])
      object = player.search_inv(object) || $manager.find(object, room)

      if object.nil?
        player.output("Close what?")
      elsif not object.can? :open
        player.output("You cannot close #{object.name}.")
      else
        object.close(event)
      end
    end
    
    def close_help(event, player, room)
      player.output <<'EOF'
Command: Close
Syntax: CLOSE [object or direction]

Closes the object. For doors and such, it is more accurate to use the direction in which the object lies.

For example:

CLOSE north

CLOSE door


See also: LOCK, UNLOCK, OPEN

EOF
    end
  end

  class CloseHandler < Aethyr::Extend::CommandHandler
    def initialize
      super(["close"])
    end

    def input_handle(input, player)
      e = case input
      when /^(close|shut)\s+(\w+)$/i
        { :action => :close, :object => $2  }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:CloseCommand, e)
    end
    
    def help_handle(input, player)
      e = case input
      when /^(close|shut)$/i
        { :action => :close_help }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:CloseCommand, e)
    end
  end

  Aethyr::Extend::HandlerRegistry.register_handler(CloseHandler)
end