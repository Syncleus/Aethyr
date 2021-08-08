require "aethyr/core/actions/commands/move"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"
require "aethyr/core/util/direction"

module Aethyr
  module Core
    module Commands
      module Move
        class MoveHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "move"
            see_also = nil
            syntax_formats = ["GO [direction or exit]"]
            aliases = ["go", "east", "west", "northeast", "northwest", "north", "southeast", "southwest", "south", "e", "w", "nw", "ne", "sw", "se", "n", "s", "up", "down", "u", "d", "in", "out"]
            content =  <<'EOF'
Move in a particular direction or through a particular exit.

Example:

GO EAST

Note that you can just use EAST, WEST, IN, OUT, UP, DOWN, etc. instead of GO.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end



          include Aethyr::Direction

          def initialize(player)
            super(player, ["go", "move", "east", "west", "northeast", "northwest", "north", "southeast", "southwest", "south", "e", "w", "nw", "ne", "sw", "se", "n", "s", "up", "down", "u", "d", "in", "out"], help_entries: MoveHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^go\s+(.*)$/i
              $manager.submit_action(Aethyr::Core::Actions::Move::MoveCommand.new(@player, :direction => $1.downcase))
            when /^(east|west|northeast|northwest|north|southeast|southwest|south|e|w|nw|ne|sw|se|n|s|up|down|u|d|in|out)(\s+\((.*)\))?$/i
              $manager.submit_action(Aethyr::Core::Actions::Move::MoveCommand.new(@player, :direction => expand_direction($1), :pre => $3))
            end
          end

          private

        end

        Aethyr::Extend::HandlerRegistry.register_handler(MoveHandler)
      end
    end
  end
end
