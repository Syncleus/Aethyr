require "aethyr/core/actions/commands/alist"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Alist
        class AlistHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "alist"
            see_also = nil
            syntax_formats = ["ALIST [ATTRIB] [QUERY]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["alist"], help_entries: AlistHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^alist$/i
              $manager.submit_action(Aethyr::Core::Actions::Alist::AlistCommand.new(@player, {}))
            when /^alist\s+(@\w+|class)\s+(.*)/i
              attrib = $2
              match = $1
              $manager.submit_action(Aethyr::Core::Actions::Alist::AlistCommand.new(@player, {:attrib => attrib, :match => match}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AlistHandler)
      end
    end
  end
end
