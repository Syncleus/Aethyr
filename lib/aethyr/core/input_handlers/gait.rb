require "aethyr/core/actions/commands/gait"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Gait
        class GaitHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "gait"
            see_also = nil
            syntax_formats = ["GAIT"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["gait"], help_entries: GaitHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^gait(\s+(.*))?$/i
              phrase = $2 if $2
              $manager.submit_action(Aethyr::Core::Actions::Gait::GaitCommand.new(@player, :phrase => phrase))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(GaitHandler)
      end
    end
  end
end
