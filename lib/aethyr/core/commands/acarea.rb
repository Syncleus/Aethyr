require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Acarea
        class AcareaHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["acarea"])
          end

          def self.object_added(data)
            return unless data[:game_object].is_a? Player
            data[:game_object].subscribe(AcareaHandler.new(data[:game_object]))
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