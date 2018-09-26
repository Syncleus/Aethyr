require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module OpenCommand
  class << self
    #Open anything openable
    def open(event, player, room)
      object = expand_direction(event[:object])
      object = player.search_inv(object) || $manager.find(object, room)

      if object.nil?
        player.output("Open what?")
      elsif not object.can? :open
        player.output("You cannot open #{object.name}.")
      else
        object.open(event)
      end
    end
    
    def open_help(event, player, room)
      player.output <<'EOF'
Command: Open
Syntax: OPEN [object or direction]

Opens the object. For doors and such, it is more accurate to use the direction in which the object lies.

For example:

OPEN north

OPEN door


See also: LOCK, UNLOCK, CLOSE

EOF
    end
  end

  class OpenHandler < Aethyr::Extend::CommandHandler
    def initialize
      super(["open"])
    end

    def input_handle(input, player)
      e = case input
      when /^open\s+(\w+)$/i
        { :action => :open, :object => $1 }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:OpenCommand, e)
    end
    
    def help_handle(input, player)
      e = case input
      when /^open$/i
        { :action => :open_help }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:OpenCommand, e)
    end
  end

  Aethyr::Extend::HandlerRegistry.register_handler(OpenHandler)
end