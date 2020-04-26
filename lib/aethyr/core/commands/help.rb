require 'aethyr/core/registry'
require 'aethyr/core/commands/command_handler'

module Aethyr
  module Core
    module Commands
      module Help
        class HelpHandler < Aethyr::Extend::CommandHandler
          def self.object_added(data)
            super(data, self)
          end

          def initialize(player)
            super(player, ["help"])
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(help|help topics)$/i
              self.player.output("Help topics available: " + player.help_library.topics.join(", "), false)
            end
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(HelpHandler)
      end
    end
  end
end
