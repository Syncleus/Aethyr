require "aethyr/core/actions/commands/alook"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Alook
        class AlookHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "alook"
            see_also = nil
            syntax_formats = ["ALOOK [OBJECT]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["alook"], help_entries: AlookHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^alook$/i
              $manager.submit_action(Aethyr::Core::Actions::Alook::AlookCommand.new(@player, {}))
            when /^alook\s+(.*)$/i
              at = $1
              $manager.submit_action(Aethyr::Core::Actions::Alook::AlookCommand.new(@player, {:at => at}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AlookHandler)
      end
    end
  end
end
