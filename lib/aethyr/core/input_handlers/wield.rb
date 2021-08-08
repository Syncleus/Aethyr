require "aethyr/core/actions/commands/wield"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Wield
        class WieldHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "wield"
            see_also = ["UNWIELD"]
            syntax_formats = ["WIELD <item>", "WIELD <item> <left|right>"]
            aliases = nil
            content =  <<'EOF'
This command causes you to wield an item. The item must be wieldable and be present in your inventory.

You can also specify which hand with which to wield the weapon. If you do not, it will favor your right hand.

Example:

WIELD sword left

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["wield"], help_entries: WieldHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^wield\s+(.*?)(\s+(\w+))?$/i
              weapon = $1
              side = $3
              $manager.submit_action(Aethyr::Core::Actions::Wield::WieldCommand.new(@player, :weapon => weapon, :side => side))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(WieldHandler)
      end
    end
  end
end
