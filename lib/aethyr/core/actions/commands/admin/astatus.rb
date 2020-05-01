require "aethyr/core/registry"
require "aethyr/core/actions/commands/admin/admin_handler"

module Aethyr
  module Core
    module Commands
      module Astatus
        class AstatusHandler < Aethyr::Extend::AdminHandler

          def self.create_help_entries
            help_entries = []

            command = "astatus"
            see_also = nil
            syntax_formats = ["ASTATUS"]
            aliases = nil
            content =  <<'EOF'
Sorry no help has been written for this command yet
EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["astatus"], help_entries: AstatusHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^astatus/i
              astatus({})
            end
          end

          private
          def astatus(event)

            room = $manager.get_object(@player.container)
            player = @player
            awho(event, player, room)
            total_objects = $manager.game_objects_count
            player.output("Object Counts:" , true)
            $manager.type_count.each do |obj, count|
              player.output("#{obj}: #{count}", true)
            end
            player.output("Total Objects: #{total_objects}")
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(AstatusHandler)
      end
    end
  end
end
