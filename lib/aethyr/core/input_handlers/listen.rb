require "aethyr/core/actions/commands/listen"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Listen
        class ListenHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "listen"
            see_also = nil
            syntax_formats = ["LISTEN [target]"]
            aliases = nil
            content =  <<'EOF'
Listen to the specified target.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["listen"], help_entries: ListenHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(listen)(\s+(.+))?$/i
              $manager.submit_action(Aethyr::Core::Actions::Listen::ListenCommand.new(@player, { :target => $3}))
            end
          end
        end
        Aethyr::Extend::HandlerRegistry.register_handler(ListenHandler)
      end
    end
  end
end
