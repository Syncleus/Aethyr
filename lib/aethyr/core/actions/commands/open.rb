require "aethyr/core/registry"
require "aethyr/core/actions/commands/command_handler"
require "aethyr/core/util/direction"

module Aethyr
  module Core
    module Commands
      module Open
        class OpenHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "open"
            see_also = ["LOCK", "UNLOCK", "CLOSE"]
            syntax_formats = ["OPEN [object or direction]"]
            aliases = nil
            content =  <<'EOF'
Opens the object. For doors and such, it is more accurate to use the direction in which the object lies.

For example:

OPEN north

OPEN door

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          include Aethyr::Direction

          def initialize(player)
            super(player, ["open"], help_entries: OpenHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^open\s+(\w+)$/i
              action({ :object => $1 })
            end
          end

          private
          def action(event)
            room = $manager.get_object(@player.container)
            object = expand_direction(event[:object])
            object = player.search_inv(object) || $manager.find(object, room)

            if object.nil?
              player.output("Open what?")
            elsif not object.can? :open
              player.output("You cannot open #{object.name}.")
            else
              object.open(event)
            end
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(OpenHandler)
      end
    end
  end
end
