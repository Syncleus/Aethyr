require "aethyr/core/actions/commands/aput"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Aput
        class AputHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "aput"
            see_also = nil
            syntax_formats = ["APUT [OBJECT] IN [CONTAINER]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["aput"], help_entries: AputHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^aput\s+(.*?)\s+in\s+(.*?)\s+at\s+(.*?)$/i
              object = $1
              in_var = $2
              at = $3
              $manager.submit_action(Aethyr::Core::Actions::Aput::AputCommand.new(@player, {:object => object, :in => in_var, :at => at}))
            when /^aput\s+(.*?)\s+in\s+(.*?)$/i
              object = $1
              in_var = $2
              $manager.submit_action(Aethyr::Core::Actions::Aput::AputCommand.new(@player, {:object => object, :in => in_var}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AputHandler)
      end
    end
  end
end
