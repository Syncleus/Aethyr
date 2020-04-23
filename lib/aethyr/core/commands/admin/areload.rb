require "aethyr/core/registry"
require "aethyr/core/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Areload
        class AreloadHandler < Aethyr::Extend::AdminHandler
          def initialize(player)
            super(player, ["areload"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^areload\s+(.*)$/i
              object = $1
              areload({:object => object})
            when /^help (areload)$/i
              action_help_areload({})
            end
          end

          private
          def action_help_areload(event)
            @player.output <<'EOF'
Sorry no help has been written for this command yet
EOF
          end


          def areload(event)

            room = $manager.get_object(@player.container)
            player = @player
            begin
              result = load "#{event[:object]}.rb"
              player.output "Reloaded #{event[:object]}: #{result}"
            rescue LoadError
              player.output "Unable to load #{event[:object]}"
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AreloadHandler)
      end
    end
  end
end
