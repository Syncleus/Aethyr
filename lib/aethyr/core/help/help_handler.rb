module Aethyr
  
  module Help
    module HandleHelp
      attr_reader :commands
      
      def initialize(commands, help_text = nil, *args)
        super
        
        @commands = commands
        @help_text = help_text
      end
      
      def help_handle(input, player)
          return "This command has no associated help text." if help_text.nil?
          @help_text
      end
    end
  end
  
  module Extend
    class HelpHandler
      include Aethyr::Help::HandleHelp
      
      def initialize(commands, help_text = nil, *args)
        super
      end
    end
  end
end