require "aethyr/core/actions/commands/kick"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Kick
        class KickHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "kick"
            see_also = nil
            syntax_formats = ["KICK"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["kick"], help_entries: KickHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^kick$/i
              $manager.submit_action(Aethyr::Core::Actions::Kick::KickCommand.new(@player, ))
            when /^kick\s+(.*)$/i
              target = $1
              $manager.submit_action(Aethyr::Core::Actions::Kick::KickCommand.new(@player, :target => target))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(KickHandler)
      end
    end
  end
end
