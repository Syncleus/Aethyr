require "aethyr/core/actions/commands/acreate"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Acexit
        class AcexitHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "acexit"
            see_also = nil
            syntax_formats = ["ACEXIT [DIRECTION] [EXIT_ROOM]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["acexit"], help_entries: AcexitHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^acexit\s+(\w+)\s+(.*)$/i
              object = "exit"
              alt_names = [$1.strip]
              args = [$2.strip]
              $manager.submit_action(Aethyr::Core::Actions::Acreate::AcreateCommand.new(@player, :object => object, :alt_names => alt_names, :args => args))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AcexitHandler)
      end
    end
  end
end
