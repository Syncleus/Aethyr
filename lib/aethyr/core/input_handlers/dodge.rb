require "aethyr/core/actions/commands/simple_dodge"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Dodge
        class DodgeHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "dodge"
            see_also = nil
            syntax_formats = ["DODGE"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["dodge"], help_entries: DodgeHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^dodge(\s+(.*))?$/i
              target = $2 if $2
              $manager.submit_action(Aethyr::Core::Actions::SimpleDodge::SimpleDodgeCommand.new(@player, :target => target))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(DodgeHandler)
      end
    end
  end
end
