require "aethyr/core/actions/commands/feel"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Feel
        class FeelHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "feel"
            see_also = nil
            syntax_formats = ["FEEL [target]"]
            aliases = nil
            content =  <<'EOF'
Feel the specified target.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ['feel'], help_entries: FeelHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(feel)(\s+(.+))?$/i
              $manager.submit_action(Aethyr::Core::Actions::Feel::FeelCommand.new(@player,  :target => $3))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(FeelHandler)
      end
    end
  end
end
