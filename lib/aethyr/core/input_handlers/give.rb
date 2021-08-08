require "aethyr/core/actions/commands/give"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Give
        class GiveHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "give"
            see_also = ["GET"]
            syntax_formats = ["GIVE [object] TO [person]"]
            aliases = nil
            content =  <<'EOF'
Give an object to someone else. Beware, though, they may not want to give it back.

At the moment, the object must be in your inventory.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["give"], help_entries: GiveHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^give\s+((\w+\s*)*)\s+to\s+(\w+)/i
              $manager.submit_action(Aethyr::Core::Actions::Give::GiveCommand.new(@player,  :item => $2.strip, :to => $3 ))
            end
          end

          private

          #Gives an item to someone else.

        end

        Aethyr::Extend::HandlerRegistry.register_handler(GiveHandler)
      end
    end
  end
end
