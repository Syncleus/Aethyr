require "aethyr/core/actions/commands/setpassword"
require "aethyr/core/actions/commands/set"
require "aethyr/core/actions/commands/showcolors"
require "aethyr/core/actions/commands/setcolor"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Set
        class SetHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "set"
            see_also = ["WORDWRAP", "PAGELENGTH", "DESCRIPTION", "COLORS", "LAYOUT"]
            syntax_formats = ["SET <option> [value]"]
            aliases = nil
            content =  <<'EOF'
There are several settings available to you. To see them all, simply use SET.
To see the values available for a certain setting, use SET <option> without a value.

Example:

To see your color settings, use

SET COLOR

To turn off word wrap, use

SET WORDWRAP OFF

To turn on full layout for larger displays, use

SET LAYOUT full

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["set"], help_entries: SetHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^set\s+colors?\s+(on|off|default)$/i
              option = $1
              $manager.submit_action(Aethyr::Core::Actions::Setcolor::SetcolorCommand.new(@player, :option => option))
            when /^set\s+colors?.*/i
              $manager.submit_action(Aethyr::Core::Actions::Showcolors::ShowcolorsCommand.new(@player, ))
            when /^set\s+colors?\s+(\w+)\s+(.+)$/i
              option = $1
              color = $2
              $manager.submit_action(Aethyr::Core::Actions::Setcolor::SetcolorCommand.new(@player, :option => option, :color => color))
            when /^set\s+password$/i
              $manager.submit_action(Aethyr::Core::Actions::Setpassword::SetpasswordCommand.new(@player, ))
            when /^set\s+(\w+)\s*(.*)$/i
              setting = $1.strip
              value = $2.strip if $2
              $manager.submit_action(Aethyr::Core::Actions::Set::SetCommand.new(@player, :setting => setting, :value => value))
            end
          end

          private




        end
        Aethyr::Extend::HandlerRegistry.register_handler(SetHandler)
      end
    end
  end
end
