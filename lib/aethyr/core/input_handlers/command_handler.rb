require 'aethyr/core/util/publisher'
require 'aethyr/core/objects/player'

module Aethyr
  module Extend
    module HandleHelp
      attr_reader :commands

      def initialize(player, commands, *args, help_entries: [], **kwargs)
        super(player, *args, **kwargs)

        @commands = commands

        help_entries.each do |entry|
          player.help_library.entry_register entry
        end
      end

      def can_help?
        true
      end
    end

    class InputHandler
      attr_reader :player

      def initialize(player, *args, **kwargs)
        super()
        @player = player
      end

      def player_input(data)
          false
      end
    end

    class CommandHandler < InputHandler
      include Aethyr::Extend::HandleHelp

      def initialize(player, commands, *args, help_entries: [], **kwargs)
        super(player, commands, *args, help_entries: help_entries, **kwargs)
      end

      protected
      #event listener parent that listens for when a new user is added to the manager
      def self.object_added(data, handler_class = self)
        #Subscribes the handler to the object that was added, assuming that object was a player.
        is_player = data[:game_object].is_a?(Aethyr::Core::Objects::Player)
        is_mock_player = defined?(Aethyr::Core::Objects::MockPlayer) && data[:game_object].is_a?(Aethyr::Core::Objects::MockPlayer)
        
        return unless is_player || is_mock_player
        data[:game_object].subscribe(handler_class.new(data[:game_object]))
      end
    end
  end
end
