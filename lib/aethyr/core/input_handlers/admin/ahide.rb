require "aethyr/core/actions/commands/ahide"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Ahide
        class AhideHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "ahide"
            see_also = nil
            syntax_formats = ["AHIDE"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["ahide"], help_entries: AhideHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^ahide\s+(.*)$/i
              object = $1
              hide = true
              $manager.submit_action(Aethyr::Core::Actions::Ahide::AhideCommand.new(@player, {:object => object, :hide => hide}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AhideHandler)
      end
    end
  end
end
