require "aethyr/core/actions/commands/smell"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Smell
        class SmellHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "smell"
            see_also = nil
            syntax_formats = ["SMELL [target]"]
            aliases = ["sniff"]
            content =  <<'EOF'
Smell the specified target.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["smell", "sniff"], help_entries: SmellHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(smell|sniff)(\s+(.+))?$/i
              $manager.submit_action(Aethyr::Core::Actions::Smell::SmellCommand.new(@player, { :target => $3}))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(SmellHandler)
      end
    end
  end
end
