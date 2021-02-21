require "aethyr/core/actions/commands/aconfig"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Aconfig
        class AconfigHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "aconfig"
            see_also = nil
            syntax_formats = ["ACONFIG", "ACONFIG RELOAD", "ACONFIG [SETTING] [VALUE]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["aconfig"], help_entries: AconfigHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^aconfig(\s+reload)?$/i
              setting = "reload" if $1
              $manager.submit_action(Aethyr::Core::Actions::Aconfig::AconfigCommand.new(@player, {:setting => setting}))
            when /^aconfig\s+(\w+)\s+(.*)$/i
              setting = $1
              value = $2
              $manager.submit_action(Aethyr::Core::Actions::Aconfig::AconfigCommand.new(@player, {:setting => setting, :value => value}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AconfigHandler)
      end
    end
  end
end
