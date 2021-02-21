require "aethyr/core/actions/commands/wear"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Wear
        class WearHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "wear"
            see_also = ["REMOVE", "INVENTORY"]
            syntax_formats = ["WEAR <object>"]
            aliases = nil
            content =  <<'EOF'
Sytnax: WEAR <object> ON <body part>

Wear an object. Objects usually have specific places they may be worn.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["wear"], help_entries: WearHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^wear\s+(\w+)(\s+on\s+(.*))?$/i
              object = $1
              position = $3
              $manager.submit_action(Aethyr::Core::Actions::Wear::WearCommand.new(@player, {:object => object, :position => position}))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(WearHandler)
      end
    end
  end
end
