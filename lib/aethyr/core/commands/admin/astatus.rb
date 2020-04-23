require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Astatus
        class AstatusHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["astatus"])
          end

          def self.object_added(data)
            super(data, klass: self)
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
