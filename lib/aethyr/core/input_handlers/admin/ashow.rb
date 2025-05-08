require "aethyr/core/actions/commands/ahide"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Ashow
        class AshowHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "ashow"
            see_also = nil
            syntax_formats = ["ASHOW"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["ashow"], help_entries: AshowHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^ashow\s+(.*)$/i
              object = $1
              hide = false
              $manager.submit_action(Aethyr::Core::Actions::Ahide::AhideCommand.new(@player, :object => object, :hide => hide))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AshowHandler)
      end
    end
  end
end
