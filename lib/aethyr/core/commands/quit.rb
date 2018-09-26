require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module QuitCommand
  class << self
    def quit(event, player, room)
      $manager.drop_player player
    end
    
    def quit_help(event, player, room)
      player.output <<'EOF'
Command: Quit
Syntax: QUIT

Saves your character and logs you off from the game.

You shouldn't need this too often.

EOF
    end
  end

  class QuitHandler < Aethyr::Extend::CommandHandler
    def initialize
      super(["quit"])
    end

    def input_handle(input, player)
      e = case input
      when /^quit$/i
        { :action => :quit }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:QuitCommand, e)
    end
    
    def help_handle(input, player)
      e = case input
      when /^quit$/i
        { :action => :quit_help }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:QuitCommand, e)
    end
  end

  Aethyr::Extend::HandlerRegistry.register_handler(QuitHandler)
end