require "aethyr/core/actions/commands/aforce"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Aforce
        class AforceHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "aforce"
            see_also = nil
            syntax_formats = ["AFORCE [OBJECT] [ACTION]"]
            aliases = nil
            content =  <<'EOF'
Forces another player to execute a command.
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["aforce"], help_entries: AforceHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^aforce\s+(.*?)\s+(.*)$/i
              target = $1
              command = $2
              $manager.submit_action(Aethyr::Core::Actions::Aforce::AforceCommand.new(@player, {:target => target, :command => command}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AforceHandler)
      end
    end
  end
end
