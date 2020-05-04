require "aethyr/core/registry"
require "aethyr/core/actions/commands/command_handler"

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
              action({ :item => $2.strip, :to => $3 })
            end
          end
          
          private
          
          #Gives an item to someone else.
          def action(event)
            room = $manager.get_object(@player.container)
            item = player.inventory.find(event[:item])

            if item.nil?
              if response = player.equipment.worn_or_wielded?(event[:item])
                player.output response
              else
                player.output "You do not seem to have a #{event[:item]} to give away."
              end

              return
            end

            receiver = $manager.find(event[:to], room)

            if receiver.nil?
              player.output("There is no #{event[:to]}.")
              return
            elsif not receiver.is_a? Player and not receiver.is_a? Mobile
              player.output("You cannot give anything to #{receiver.name}.")
              return
            end

            player.inventory.remove(item)
            receiver.inventory.add(item)

            event[:target] = receiver
            event[:to_player] = "You give #{item.name} to #{receiver.name}."
            event[:to_target] = "#{player.name} gives you #{item.name}."
            event[:to_other] = "#{player.name} gives #{item.name} to #{receiver.name}."

            room.out_event(event)
          end
        end

        Aethyr::Extend::HandlerRegistry.register_handler(GiveHandler)
      end
    end
  end
end