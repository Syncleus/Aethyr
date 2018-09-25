module Aethyr
  module Extend
    class InputHandler
      def initialize
        super
      end

      def handle(input, player)
          false
      end
    end
    
    class CommandHandler
      attr_reader :commands
      
      def initialize(commands, help_text = nil)
        super()
        
        @commands = commands
        @help_text = help_text
      end

      def help(input, player)
          return "This command has no associated help text." if help_text.nil?
          @help_text
      end
    end
  end
end