require "aethyr/core/actions/commands/acroom"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Acroom
        class AcroomHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "acroom"
            see_also = nil
            syntax_formats = ["ACROOM [OUT_DIRECTION] [NAME]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["acroom"], help_entries: AcroomHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^acroom\s+(\w+)\s+(.*)$/i
              out_dir = $1
              in_dir = opposite_dir($1)
              name = $2
              $manager.submit_action(Aethyr::Core::Actions::Acroom::AcroomCommand.new(@player, {:out_dir => out_dir, :in_dir => in_dir, :name => name}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AcroomHandler)
      end
    end
  end
end
