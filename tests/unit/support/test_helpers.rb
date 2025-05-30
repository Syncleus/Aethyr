module Aethyr
  module Core
    module Objects
      # Mock implementation of Player for testing
      class MockPlayer
        attr_accessor :admin, :subscribed_handler, :help_library
        
        def initialize
          @subscribed_handler = nil
          @admin = false
        end
        
        def subscribe(handler)
          @subscribed_handler = handler
        end
        
        def output(message, newline = true)
          # No-op for tests
        end
        
        # Mimic the Player class's help_library method
        def help_library
          @help_library ||= HelpLibraryStub.new
        end
      end
      
      # Simple stub for HelpLibrary
      class HelpLibraryStub
        def entry_register(entry); end
        def topics; []; end
        def render_topic(topic); 'help text'; end
      end
    end
  end
end 