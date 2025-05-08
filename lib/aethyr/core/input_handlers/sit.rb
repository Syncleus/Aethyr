require "aethyr/core/actions/commands/sit"
require "aethyr/core/registry"
require "aethyr/core/input_handlers/command_handler"

module Aethyr
  module Core
    module Commands
      module Sit
        class SitHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "sit"
            see_also = ["STAND"]
            syntax_formats = ["SIT", "SIT ON <object>"]
            aliases = nil
            content =  <<'EOF'
Using this command, you can sit on things like chairs and benches. When used without an object, you will sit down on the ground.

Note that you must stand up before you can move anywhere.

Example:

SIT ON stool

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["sit"], help_entries: SitHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^sit\s+on\s+(.*)$/i, /^sit\s+(.*)$/i, /^sit$/i
              object = $1.strip if $1
              $manager.submit_action(Aethyr::Core::Actions::Sit::SitCommand.new(@player, :object => object))
            end
          end

          private

        end
        Aethyr::Extend::HandlerRegistry.register_handler(SitHandler)
      end
    end
  end
end
