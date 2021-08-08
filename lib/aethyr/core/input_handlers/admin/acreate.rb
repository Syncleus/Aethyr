require "aethyr/core/actions/commands/acreate"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Acreate
        class AcreateHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "acreate"
            see_also = nil
            syntax_formats = ["ACREATE [OBJECT_TYPE] [NAME]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["acreate"], help_entries: AcreateHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^(ac|acreate)\s+(\w+)\s*(.*)$/i
              object = $2
              name = $3.strip
              $manager.submit_action(Aethyr::Core::Actions::Acreate::AcreateCommand.new(@player, :object => object, :name => name))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AcreateHandler)
      end
    end
  end
end
