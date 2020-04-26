require "aethyr/core/registry"

module Aethyr
  module Extend
    module HandleHelp
      attr_reader :commands

      def initialize(player, commands, *args, help_entries: [])
        super(player, *args)

        @commands = commands

        help_entries.each do |entry|
          player.help_library.entry_register entry
        end
      end

      def can_help?
        true
      end
    end

    class HelpEntryHandler
      include Aethyr::Extend::HandleHelp

      def initialize(player, commands, *args, help_entries: [])
        super
      end
    end
  end
end
