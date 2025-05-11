require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Extend
    class HelpEntryHandler
      include Aethyr::Extend::HandleHelp

      def initialize(player, commands, *args, help_entries: [], **kwargs)
        super
      end
    end
  end
end
