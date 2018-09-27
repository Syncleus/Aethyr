require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Open
        class OpenHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["open"])
          end
          
          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(OpenHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^open\s+(\w+)$/i
              action({ :object => $1 })
            when /^help open$/i
              action_help({})
            end
          end
          
          private
          def action_help(event)
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
          
          def action(event)
            room = $manager.get_object(@player.container)
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
        end

        Aethyr::Extend::HandlerRegistry.register_handler(OpenHandler)
      end
    end
  end
end