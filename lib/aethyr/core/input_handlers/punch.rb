require "aethyr/core/actions/commands/punch"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Punch
        class PunchHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "punch"
            see_also = nil
            syntax_formats = ["PUNCH"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["punch"], help_entries: PunchHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^punch$/i
              $manager.submit_action(Aethyr::Core::Actions::Punch::PunchCommand.new(@player, {}))
            when /^punch\s+(.*)$/i
              target = $1
              $manager.submit_action(Aethyr::Core::Actions::Punch::PunchCommand.new(@player, {:target => target}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(PunchHandler)
      end
    end
  end
end
