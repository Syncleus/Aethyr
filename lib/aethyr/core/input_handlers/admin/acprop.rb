require "aethyr/core/actions/commands/acreate"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Acprop
        class AcpropHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "acprop"
            see_also = nil
            syntax_formats = ["ACPROP [GENERIC]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["acprop"], help_entries: AcpropHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^acprop\s+(.*)$/i
              object = "prop"
              generic = $1
              $manager.submit_action(Aethyr::Core::Actions::Acreate::AcreateCommand.new(@player, {:object => object, :generic => generic}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AcpropHandler)
      end
    end
  end
end
