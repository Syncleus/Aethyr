require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Ahelp
        class AhelpHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["ahelp"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^ahelp(.*)$/i
              object = $1
              ahelp({:object => object})
            when /^help (ahelp)$/i
              action_help_ahelp({})
            end
          end

          private
          def action_help_ahelp(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def ahelp(event)

            room = $manager.get_object(@player.container)
            player = @player
            Generic.help(event, player, room)
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AhelpHandler)
      end
    end
  end
end
