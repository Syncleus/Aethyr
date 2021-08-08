require "aethyr/core/actions/commands/awatch"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Awatch
        class AwatchHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "awatch"
            see_also = nil
            syntax_formats = ["AWATCH"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["awatch"], help_entries: AwatchHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^awatch\s+((start|stop)\s+)?(.*)$/i
              target = $3.downcase if $3
              command = $2.downcase if $2
              $manager.submit_action(Aethyr::Core::Actions::Awatch::AwatchCommand.new(@player, :target => target, :command => command))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AwatchHandler)
      end
    end
  end
end
