require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Acarea
        class AcareaHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["acarea"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^acarea\s+(.*)$/i
              name = $1.strip
              acarea({:name => name})
            when /^help (acarea)$/i
              action_help_acarea({})
            end
          end

          private
          def action_help_acarea(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def acarea(event)

            room = $manager.get_object(@player.container)
            player = @player
            area = $manager.create_object(Area, nil, nil, nil, {:@name => event[:name]})
            player.output "Created: #{area}"
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AcareaHandler)
      end
    end
  end
end
