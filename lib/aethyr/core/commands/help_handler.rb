require "aethyr/core/registry"

module Aethyr
  module Extend
    module HandleHelp
      attr_reader :commands
      
      def initialize(commands, help_text = nil, *args)
        super(*args)
        
        @commands = commands
        @help_text = help_text
      end
      
      def help_handle(input, player)
          return "This command has no associated help text." if help_text.nil?
          @help_text
      end
      
      def can_help?(player)
        true
      end
    end

    class HelpHandler
      include Aethyr::Extend::HandleHelp
      
      def initialize(commands, help_text = nil, *args)
        super
      end
    end
  end
end

module HelpCommand
  class << self
    #Display help.
    def help(event, player, room)
        player.output('Help topics available:', true)
        topics = Aethyr::Extend::HandlerRegistry.help_topics(player)
        player.output(topics.join(' ').upcase)
    end
  end

  class HelpHandler < Aethyr::Extend::HelpHandler
    def initialize
      super(["help"])
    end
    
    def help_handle(input, player)
      e = case input
      when /^$/i
        { :action => :help }
      when /^topics$/i
        { :action => :help }
      else
        nil
      end

      return nil if e.nil?
      Event.new(:HelpCommand, e)
    end
  end

  Aethyr::Extend::HandlerRegistry.register_handler(HelpHandler)
end