require "aethyr/core/actions/commands/command_action"

module Aethyr
  module Core
    module Actions
      module Inventory
        class InventoryCommand < Aethyr::Extend::CommandAction
          def initialize(actor, **data)
            super(actor, **data)
          end

          def action
            event = @data
            player.output(player.show_inventory)
          end
        end
      end
    end
  end
end
