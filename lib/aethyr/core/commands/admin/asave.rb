require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Asave
        class AsaveHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["asave"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^asave$/i
              asave({})
            when /^help (asave)$/i
              action_help_asave({})
            end
          end

          private
          def action_help_asave(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def asave(event)

            room = $manager.get_object(@player.container)
            player = @player
            log "#{player.name} initiated manual save."
            $manager.save_all
            player.output "Save complete. Check log for details."
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AsaveHandler)
      end
    end
  end
end
