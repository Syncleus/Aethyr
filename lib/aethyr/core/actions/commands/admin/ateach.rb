require "aethyr/core/registry"
require "aethyr/core/actions/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Ateach
        class AteachHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "ateach"
            see_also = nil
            syntax_formats = ["ATEACH [OBJECT] [SKILL]"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["ateach"], help_entries: AteachHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^ateach\s+(\w+)\s+(\w+)$/i
              target = $1
              skill = $2
              ateach({:target => target, :skill => skill})
            end
          end

          private
          def ateach(event)

            room = $manager.get_object(@player.container)
            player = @player
            object = find_object(event[:target], event)
            if object.nil?
              player.output "Teach who what where?"
              return
            end

            alearn(event, object, room)
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AteachHandler)
      end
    end
  end
end
