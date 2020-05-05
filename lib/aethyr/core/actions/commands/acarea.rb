require "aethyr/core/actions/command_action"

module Aethyr
  module Core
    module Actions
      module Acarea
        class AcareaCommand < Aethyr::Core::Actions::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data

            room = $manager.get_object(@player.container)
            player = @player
            area = $manager.create_object(Area, nil, nil, nil, {:@name => event[:name]})
            player.output "Created: #{area}"
          end

        end
      end
    end
  end
end
