require "aethyr/core/actions/commands/stand"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Stand
        class StandHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "stand"
            see_also = ["SIT"]
            syntax_formats = ["STAND"]
            aliases = nil
            content =  <<'EOF'
Stand up if you are sitting down.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["stand"], help_entries: StandHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^stand$/i
              $manager.submit_action(Aethyr::Core::Actions::Stand::StandCommand.new(@player, ))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(StandHandler)
      end
    end
  end
end
