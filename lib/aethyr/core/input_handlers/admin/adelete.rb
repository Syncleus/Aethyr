require "aethyr/core/actions/commands/adelete"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Adelete
        class AdeleteHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "adelete"
            see_also = nil
            syntax_formats = ["ADELETE [OBJECT]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["adelete"], help_entries: AdeleteHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^adelete\s+(.*)$/i
              object = $1
              $manager.submit_action(Aethyr::Core::Actions::Adelete::AdeleteCommand.new(@player, :object => object))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AdeleteHandler)
      end
    end
  end
end
