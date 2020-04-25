require 'aethyr/core/commands/help_handler'

module Aethyr
  module Extend

    class InputHandler
      attr_reader :player

      def initialize(player, *args)
        super()
        @player = player
      end

      def player_input(data)
          false
      end
    end

    class CommandHandler < InputHandler
      include Aethyr::Extend::HandleHelp

      def initialize(player, commands, *args, help_entries: [])
        super(player, commands, *args, help_entries: help_entries)
      end

      protected
      #event listener parent that listens for when a new user is added to the manager
      def self.object_added(data, child_class)
        return unless data[:game_object].is_a? Player
        data[:game_object].subscribe(child_class.new(data[:game_object]))
      end

    end
  end
end
