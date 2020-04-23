require 'aethyr/core/commands/command_handler'

module Aethyr
  module Extend
    class AdminHandler < CommandHandler
      def initialize(player, commands, *args)
        super(player, commands, *args)
      end

      def self.admin_object_added(data, klass)
        return unless (data[:game_object].is_a? Player) && data[:game_object].admin
        data[:game_object].subscribe(klass.new(data[:game_object]))
      end

      protected
      #Tail a file
      def tail file, lines = 10
        require 'util/tail'

        output = []
        File::Tail::Logfile.tail(file, :backward => lines, :return_if_eof => true) do |line|
          output << line.strip
        end

        output << "(#{output.length} lines shown.)"
      end

      #Looks in player's inventory and room for name.
      #Then checks at global level for GOID.
      def find_object(name, event)
        $manager.find(name, event[:player]) || $manager.find(name, event[:player].container) || $manager.get_object(name)
      end

    end
  end
end
