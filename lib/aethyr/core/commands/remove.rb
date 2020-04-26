require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Remove
        class RemoveHandler < Aethyr::Extend::CommandHandler

          def self.create_help_entries
            help_entries = []

            command = "remove"
            see_also = ["WEAR", "INVENTORY"]
            syntax_formats = ["REMOVE <object>"]
            aliases = nil
            content =  <<'EOF'
Remove an article of clothing or armor.

EOF
            help_entries.push(Aethyr::Core::Help::HelpEntry.new(command, content: content, syntax_formats: syntax_formats, see_also: see_also, aliases: aliases))

            return help_entries
          end


          def initialize(player)
            super(player, ["remove"], help_entries: RemoveHandler.create_help_entries)
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^remove\s+(\w+)(\s+from\s+(.*))?$/i
              object = $1
              position = $3
              remove({:object => object, :position => position})
            end
          end

          private
          def remove(event)

            room = $manager.get_object(@player.container)
            player = @player

            object = player.equipment.find(event[:object])

            if object.nil?
              player.output("What #{event[:object]} are you trying to remove?")
              return
            end

            if player.inventory.full?
              player.output("There is no room in your inventory.")
              return
            end

            if object.is_a? Weapon
              player.output("You must unwield weapons.")
              return
            end

            response = player.remove(object, event[:position])

            if response
              event[:to_player] = "You remove #{object.name}."
              event[:to_other] = "#{player.name} removes #{object.name}."
              room.out_event(event)
            else
              player.output "Could not remove #{object.name} for some reason."
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(RemoveHandler)
      end
    end
  end
end
