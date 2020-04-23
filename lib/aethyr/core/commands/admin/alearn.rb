require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Alearn
        class AlearnHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["alearn"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^alearn\s+(\w+)$/i
              skill = $1
              alearn({:skill => skill})
            when /^help (alearn)$/i
              action_help_alearn({})
            end
          end

          private
          def action_help_alearn(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def alearn(event)

            room = $manager.get_object(@player.container)
            player = @player
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AlearnHandler)
      end
    end
  end
end
