require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Ateach
        class AteachHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["ateach"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AteachHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^ateach\s+(\w+)\s+(\w+)$/i
              target = $1
              skill = $2
              ateach({:target => target, :skill => skill})
            when /^help (ateach)$/i
              action_help_ateach({})
            end
          end

          private
          def action_help_ateach(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def ateach(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:target], event)
            if object.nil?
              player.output "Teach who what where?"
              return
            end

            alearn(event, object, room)
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AteachHandler)
      end
    end
  end
end
