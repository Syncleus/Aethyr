require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Astatus
        class AstatusHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["astatus"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AstatusHandler.new(data[:game_object]))
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^astatus/i
              astatus({})
            when /^help (astatus)$/i
              action_help_astatus({})
            end
          end

          private
          def action_help_astatus(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def astatus(event)

            room = $manager.get_object(@player.container)
            player = @player
            awho(event, player, room)
            total_objects = $manager.game_objects_count
            player.output("Object Counts:" , true)
            $manager.type_count.each do |obj, count|
              player.output("#{obj}: #{count}", true)
            end
            player.output("Total Objects: #{total_objects}")
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AstatusHandler)
      end
    end
  end
end