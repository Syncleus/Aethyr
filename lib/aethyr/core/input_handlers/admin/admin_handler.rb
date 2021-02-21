require 'aethyr/core/input_handlers/command_handler'

module Aethyr
  module Extend
    class AdminHandler < CommandHandler
      def initialize(player, commands, *args, help_entries: [])
        super(player, commands, *args, help_entries: help_entries)
      end

      protected
      def self.object_added(data, child_class)
        return unless (data[:game_object].is_a? Player) && data[:game_object].admin
        data[:game_object].subscribe(child_class.new(data[:game_object]))
      end

      #Tail a file
      def tail file, lines = 10
        require 'util/tail'

        output = []
        File::Tail::Logfile.tail(file, :backward => lines, :return_if_eof => true) do |line|
          output << line.strip
        end

        output << "(#{output.length} lines shown.)"
      end
    end
  end
end
