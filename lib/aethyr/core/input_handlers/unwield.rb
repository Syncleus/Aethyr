require "aethyr/core/actions/commands/unwield"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Unwield
        class UnwieldHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "unwield"
            see_also = ["WIELD"]
            syntax_formats = ["UNWIELD", "UNWIELD <weapon>", "UNWIELD <left|right>"]
            aliases = nil
            content =  <<'EOF'
This command will cause you to unwield a weapon and place it in your inventory. If you do not specify which weapon or which hand you are using to hold the weapon, it will favor your right hand.

Example:

UNWIELD halberd
UNWIELD left

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["unwield"], help_entries: UnwieldHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^unwield(\s+(.*))?$/i
              weapon = $2
              $manager.submit_action(Aethyr::Core::Actions::Unwield::UnwieldCommand.new(@player, :weapon => weapon))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(UnwieldHandler)
      end
    end
  end
end
