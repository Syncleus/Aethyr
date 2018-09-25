require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module MapCommand
  class << self
    #map
    def map(event, player, room)
      player.output(room.area.render_map(player, room.area.position(room)))
    end
  end

  class MapHandler < Aethyr::Extend::CommandHandler
    def initialize
      super(["m", "map"])
    end

    def input_handle(input, player)
      e = case input
      when /^(m|map)$/i
        { :action => :map }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:MapCommand, e)
    end
    
    def help_handle(input, player)
      <<'EOF'
Command: Map
Syntax: MAP

Displays a map of the area.
EOF
    end
  end

  Aethyr::Extend::HandlerRegistry.register_handler(MapHandler)
end