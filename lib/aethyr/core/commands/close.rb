require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Close
        class CloseHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["close"])
          end
          
          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(CloseHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(close|shut)\s+(\w+)$/i
              action({ :object => $2  })
            when /^help (close|shut)$/i
              action_help({})
            end
          end
          
          private
          def action(event)
            room = $manager.get_object(@player.container)
            object = expand_direction(event[:object])
            object = @player.search_inv(object) || $manager.find(object, room)

            if object.nil?
              @player.output("Close what?")
            elsif not object.can? :open
              @player.output("You cannot close #{object.name}.")
            else
              object.close(event)
            end
          end
          
          def action_help(event)
            @player.output <<'EOF'
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

        Aethyr::Extend::HandlerRegistry.register_handler(CloseHandler)
      end
    end
  end
end