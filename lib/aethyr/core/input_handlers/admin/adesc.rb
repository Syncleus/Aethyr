require "aethyr/core/actions/commands/adesc"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Adesc
        class AdescHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "adesc"
            see_also = nil
            syntax_formats = ["ADESC [OBJECT] [DESCRIPTION]", "ADESC INROOM [OBJECT] [DESCRIPTION]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["adesc"], help_entries: AdescHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^adesc\s+inroom\s+(.*?)\s+(.*)$/i
              object = $1
              inroom = true
              desc = $2
              $manager.submit_action(Aethyr::Core::Actions::Adesc::AdescCommand.new(@player, :object => object, :inroom => inroom, :desc => desc))
            when /^adesc\s+(.*?)\s+(.*)$/i
              object = $1
              desc = $2
              $manager.submit_action(Aethyr::Core::Actions::Adesc::AdescCommand.new(@player, :object => object, :desc => desc))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AdescHandler)
      end
    end
  end
end
