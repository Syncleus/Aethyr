require "aethyr/core/registry"
require "aethyr/core/commands/command_handler"

module Aethyr
  module Core
    module Commands
      module Wear
        class WearHandler < Aethyr::Extend::CommandHandler
          def initialize(player)
            super(player, ["wear"])
          end

          def self.object_added(data)
            super(data, klass: self)
          end

          def player_input(data)
            super(data)
            case data[:input]
            when /^wear\s+(\w+)(\s+on\s+(.*))?$/i
              object = $1
              position = $3
              wear({:object => object, :position => position})
            when /^help (wear)$/i
              action_help_wear({})
            end
          end

          private
          def action_help_wear(event)
            @player.output <<'EOF'
Command: Wear
Syntax: WEAR <object>
Sytnax: WEAR <object> ON <body part>

Wear an object. Objects usually have specific places they may be worn.


See also: REMOVE, INVENTORY

EOF
          end


          def wear(event)

            room = $manager.get_object(@player.container)
            player = @player

            object = player.inventory.find(event[:object])

            if object.nil?
              player.output("What #{event[:object]} are you trying to wear?")
              return
            elsif object.is_a? Weapon
              player.output "You must wield #{object.name}."
              return
            end

            if player.wear object
              event[:to_player] = "You put on #{object.name}."
              event[:to_other] = "#{player.name} puts on #{object.name}."
              room.out_event(event)
            end
          end

        end
        Aethyr::Extend::HandlerRegistry.register_handler(WearHandler)
      end
    end
  end
end
