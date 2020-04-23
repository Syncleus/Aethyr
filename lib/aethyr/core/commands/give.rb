require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Give
        class GiveHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["give"])
          end
          
          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^give\s+((\w+\s*)*)\s+to\s+(\w+)/i
              action({ :item => $2.strip, :to => $3 })
            when /^help give$/i
              action_help({})
            end
          end
          
          private
          def action_help(event)
            @player.output <<'EOF'
Command: Give
Syntax: GIVE [object] TO [person]

Give an object to someone else. Beware, though, they may not want to give it back.

At the moment, the object must be in your inventory.

See also: GET

EOF
          end
          
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