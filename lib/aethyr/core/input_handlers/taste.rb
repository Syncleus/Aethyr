require "aethyr/core/actions/commands/taste"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Taste
        class TasteHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "taste"
            see_also = nil
            syntax_formats = ["TASTE [target]"]
            aliases = ["lick"]
            content =  <<'EOF'
Taste the specified target.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["lick", "taste"], help_entries: TasteHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(taste|lick)(\s+(.+))?$/i
              $manager.submit_action(Aethyr::Core::Actions::Taste::TasteCommand.new(@player,  :target => $3))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(TasteHandler)
      end
    end
  end
end
