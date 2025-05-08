require "aethyr/core/actions/commands/portal"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Portal
        class PortalHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "portal"
            see_also = nil
            syntax_formats = ["PORTAL [OBJECT] (ACTION|EXIT|ENTRANCE|PORTAL) [VALUE]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["portal"], help_entries: PortalHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^portal\s+(.*?)\s+(action|exit|entrance|portal)\s+(.*)$/i
              object = $1
              setting = $2.downcase
              value = $3.strip
              $manager.submit_action(Aethyr::Core::Actions::Portal::PortalCommand.new(@player, :object => object, :setting => setting, :value => value))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(PortalHandler)
      end
    end
  end
end
