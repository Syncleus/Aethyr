require "aethyr/core/registry"

module Aethyr
  module Extend
    module HandleHelp
      attr_reader :commands

      def initialize(player, commands, *args)
        super(player, *args)

        @commands = commands
      end

      def player_input(data)
        super(data)
        case data[:input]
        when /^(help|help topics)$/i
          if self.can_help?
            self.player.output( commands.join(" ") + " ", true)
          end
        end
      end

      def can_help?
        true
      end
    end

    class HelpHandler
      include Aethyr::Extend::HandleHelp

      def initialize(player, commands, *args)
        super
      end
    end
  end
end
