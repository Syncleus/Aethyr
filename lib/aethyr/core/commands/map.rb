require "aethyr/core/commands/command"

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

    def handle(input, player)
      e = case input
      when /^(m|map)$/i
        { :action => :map }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:MapCommand, e)
    end
  end

  Aethyr::Extend::InputHandlerRegistry.register_handler(MapHandler)
end