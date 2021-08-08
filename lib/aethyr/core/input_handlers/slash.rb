require "aethyr/core/actions/commands/slash"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Slash
        class SlashHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "slash"
            see_also = nil
            syntax_formats = ["SLASH"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["slash"], help_entries: SlashHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^slash$/i
              $manager.submit_action(Aethyr::Core::Actions::Slash::SlashCommand.new(@player, ))
            when /^slash\s+(.*)$/i
              target = $1
              $manager.submit_action(Aethyr::Core::Actions::Slash::SlashCommand.new(@player, :target => target))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(SlashHandler)
      end
    end
  end
end
