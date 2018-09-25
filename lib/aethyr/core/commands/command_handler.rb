require 'aethyr/core/help/help_handler'

module Aethyr
  module Extend
    
    class InputHandler
      def initialize(*args)
        super()
      end

      def input_handle(input, player)
          false
      end
    end
    
    class CommandHandler < InputHandler
      include Aethyr::Help::HandleHelp
      
      def initialize(commands, help_text = nil, *args)
        super
      end
    end
  end
end