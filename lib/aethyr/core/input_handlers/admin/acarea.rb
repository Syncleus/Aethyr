require "aethyr/core/actions/commands/acarea"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Acarea
        class AcareaHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "acarea"
            see_also = nil
            syntax_formats = ["ACAREA [NAME]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["acarea"], help_entries: AcareaHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^acarea\s+(.*)$/i
              name = $1.strip
              $manager.submit_action(Aethyr::Core::Actions::Acarea::AcareaCommand.new(@player, {:name => name}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AcareaHandler)
      end
    end
  end
end
