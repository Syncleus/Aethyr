require 'aethyr/core/input_handlers/command_handler'

module Aethyr
  module Extend
    class EmoteHandler < CommandHandler
      def initialize(player, commands, *args, **kwargs)
        super(player, commands, *args, **kwargs)
      end

    end
  end
end
