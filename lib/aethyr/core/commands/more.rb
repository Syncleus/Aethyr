require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module MoreCommand
  class << self
    #Display more paginated text.
    def more(event, player, room)
      player.more
    end
    
    def more_help(event, player, room)
      player.output <<'EOF'
Command: More
Syntax: MORE

When the output from the last command was too long to display you can issue this
command to see the next page. If there are multiple pages then this command can
be used multiple times.

See also: PAGELENGTH
EOF
    end
  end

  class MoreHandler < Aethyr::Extend::CommandHandler
    def initialize
      super(["more"])
    end

    def input_handle(input, player)
      e = case input
      when /^more/i
        { :action => :more }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:MoreCommand, e)
    end
    
    def help_handle(input, player)
      e = case input
      when /^more/i
        { :action => :more_help }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:MoreCommand, e)
    end
  end

  Aethyr::Extend::HandlerRegistry.register_handler(MoreHandler)
end