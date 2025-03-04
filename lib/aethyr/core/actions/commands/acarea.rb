require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Acarea
        class AcareaCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            

            room = $manager.get_object(@player.container)
            player = @player
            area = $manager.create_object(Area, nil, nil, nil, {:@name => self[:name]})
            player.output "Created: #{area}"
          end

        end
      end
    end
  end
end
