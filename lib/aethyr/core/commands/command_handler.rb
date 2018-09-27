require 'aethyr/core/commands/help_handler'

module Aethyr
  module Extend
    
    class InputHandler
      attr_reader :player
      
      def initialize(player, *args)
        super(*args)
        @player = player
      end

      def player_input(data)
          false
      end
    end
    
    class CommandHandler < InputHandler
      include Aethyr::Extend::HandleHelp
      
      def initialize(player, commands, *args)
        super(player, commands, *args)
      end
    end
  end
end