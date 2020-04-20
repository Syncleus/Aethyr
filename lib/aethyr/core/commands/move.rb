require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"
require "aethyr/core/util/direction"

module Aethyr
  module Core
    module Commands
      module Move
        class MoveHandler < Aethyr::Extend::CommandHandler

          include Aethyr::Direction

          def initialize(player)
            super(player, ["go", "move", "east", "west", "northeast", "northwest", "north", "southeast", "southwest", "south", "e", "w", "nw", "ne", "sw", "se", "n", "s", "up", "down", "u", "d", "in", "out"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(MoveHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^go\s+(.*)$/i
              action({:direction => $1.downcase})
            when /^(east|west|northeast|northwest|north|southeast|southwest|south|e|w|nw|ne|sw|se|n|s|up|down|u|d|in|out)(\s+\((.*)\))?$/i
              action({:direction => expand_direction($1),
              :pre => $3})
            when /^help (go|move|east|west|northeast|northwest|north|southeast|southwest|south|e|w|nw|ne|sw|se|n|s|up|down|u|d|in|out)$/i
              action_help({})
            end
          end

          private
          def action_help(event)
            @player.output <<'EOF'
Command: Go
Syntax: GO [direction or exit]

Move in a particular direction or through a particular exit.

Example:

GO EAST

Note that you can just use EAST, WEST, IN, OUT, UP, DOWN, etc. instead of GO.

EOF
          end

          def action(event)
            room = $manager.get_object(@player.container)
            exit = room.exit(event[:direction])

            if exit.nil?
              @player.output("You cannot go #{event[:direction]}.")
              return
            elsif exit.can? :open and not exit.open?
              @player.output("That exit is closed. Perhaps you should open it?")
              return
            end

            new_room = $manager.find(exit.exit_room)

            if new_room.nil?
              @player.output("That exit #{exit.name} leads into the void.")
              return
            end

            room.remove(@player)
            new_room.add(@player)
            @player.container = new_room.game_object_id
            event[:to_player] = "You move #{event[:direction]}."
            event[:to_other] = "#{@player.name} leaves #{event[:direction]}."
            event[:to_blind_other] = "You hear someone leave."

            room.out_event(event)
            look_text = new_room.look(player)
            out_text = Window.split_message(look_text, 79).join("\n")
            @player.output(out_text, message_type: :look, internal_clear: true)
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(MoveHandler)
      end
    end
  end
end
