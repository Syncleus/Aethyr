require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Put
        class PutHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["put"])
          end

          def self.object_added(data)
            super(data, self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^put((\s+(\d+)\s+)|\s+)(\w+)\s+in\s+(\w+)$/i
              action({ :item => $4,
                :count => $3.to_i,
                :container => $5 })
            when /^help put$/i
              action_help({})
            end
          end

          private
          def action_help(event)
            @player.output <<'EOF'
Command: Put
Syntax: PUT [object] IN [container]

Puts an object in a container. The container must be open to do so.

See also: LOOK TAKE OPEN

EOF
          end

          def action(event)
            room = $manager.get_object(@player.container)
            item = @player.inventory.find(event[:item])

            if item.nil?
              if response = @player.equipment.worn_or_wielded?(event[:item])
                @player.output response
              else
                @player.output "You do not seem to have a #{event[:item]}."
              end

              return
            end

            container = @player.search_inv(event[:container]) || $manager.find(event[:container], room)

            if container.nil?
              @player.output("There is no #{event[:container]} in which to put #{item.name}.")
              return
            elsif not container.is_a? Container
              @player.output("You cannot put anything in #{container.name}.")
              return
            elsif container.can? :open and container.closed?
              @player.output("You need to open #{container.name} first.")
              return
            end

            @player.inventory.remove(item)
            container.add(item)

            event[:to_player] = "You put #{item.name} in #{container.name}."
            event[:to_other] = "#{@player.name} puts #{item.name} in #{container.name}"

            room.out_event(event)
          end
        end
        
        Aethyr::Extend::HandlerRegistry.register_handler(PutHandler)
      end
    end
  end
end